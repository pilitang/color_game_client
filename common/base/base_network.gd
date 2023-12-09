extends BaseNode

#const base_url = "http://127.0.0.1:8080"
#const websocket_url = "ws://127.0.0.1:8889"

const base_url = "https://api.bairimengxingqiu.com"
const websocket_url = "wss://pipe.bairimengxingqiu.com:11022"

var http_client : HTTPClient = HTTPClient.new()
const MAX_REDIRECTS :int = 16384


var COLONSPACE = ": ".to_utf8_buffer()
var CRLF = "\r\n".to_utf8_buffer()
var DASHDASH = "--".to_utf8_buffer()
var boundary = "WebKitFormBoundaryePkpFF7tjBAqx29L".to_utf8_buffer()
const SECRET = "MAGIC_GYD"
func send(sub_url :String,params : Dictionary ={},object:Object =null,completed :String = "",
			show_err:bool =true,error_notify :bool = false) -> HTTPRequest:
	var request = HTTPRequest.new()
	request.use_threads = true
	request.max_redirects = MAX_REDIRECTS
	if object !=null and not completed.is_empty() :
		request.connect("request_completed",Callable(self,"send_completed").bind(request,object,completed,show_err,error_notify),CONNECT_ONE_SHOT)
	add_child(request)
	if not params.has("uId"):
		params["uId"]  = Account.UID
	params["appName"]  = "dreamdearplanet"
	params["deviceOs"]  = OS.get_name() 
	params["deviceOp"]  = SysUtil.deviceOp()
	params["deviceType"]  = SysUtil.deviceType()
	params["appVersion"]  = SysUtil.appVersion()
	params["apiVersion"]  = SysUtil.apiVersion()
	params["ts"]  = str(TimeUtil.serverTimeSeconds())
	params["engineVersion"]  = Engine.get_version_info().string
	var signStr = JsonWrapper.toJson(params)+SECRET
	params["sign"]  = signStr.md5_text()
	var query_string = http_client.query_string_from_dict(params)
	print_debug("\n"+base_url+sub_url+"?"+query_string+"\n")
	var headers = ["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(query_string.length())]
	var error = request.request(base_url+sub_url,headers,  HTTPClient.METHOD_POST,query_string)
	if error != OK:
		push_error("An error occurred in the HTTP request.")
	return request

func send_completed(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray,
			request_http:Node,request_object:Object,request_method :String,show_err:bool =true,error_notify :bool = false):
	remove_child(request_http)
	if request_object == null or request_method.is_empty() or request_object.is_queued_for_deletion() : return
	var data = parse_send_result(result,_response_code,body,show_err)
	if data == null and not error_notify : return
	var _err = connect("result_data",Callable(request_object,request_method).bind(),CONNECT_ONE_SHOT)
	emit_signal("result_data",data)

func parse_send_result(result: int, _response_code: int, body: PackedByteArray,show_err:bool =true) :
	if(result != HTTPRequest.RESULT_SUCCESS || _response_code !=200 ):
		print_debug("HTTPRequest send error result : ",result," _response_code : ",_response_code)
		return null
	var json = JsonWrapper.convertJson(body.get_string_from_utf8())
	if(json.error.errno != 200):
		print_debug("HTTPRequest send error from server : ",json.error.errmsg)
		if(show_err and not json.error.usermsg.is_empty()) : ToastRouter.showToast(json.error.usermsg)
		return null
	if json.data == null:
		return {} 
	return json.data


func downloadFile(url :String,object:Object =null,completed :String = "",show_err:bool =true ,error_notify :bool = false,append = null,failCal = Callable()) -> HTTPRequest:
	var request = HTTPRequest.new()
	request.use_threads = true
	request.max_redirects = MAX_REDIRECTS
	if object !=null and not completed.is_empty() :
		request.connect("request_completed",Callable(self,"downloadFile_completed").bind(request,object,completed,show_err,error_notify,append,failCal ),CONNECT_ONE_SHOT)
	add_child(request)
	var error = request.request(url)
	if error != OK:
		print_debug("An error occurred in the HTTP request.")
	return request
	
func downloadFile_completed(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray,
			request_http:Node,request_object,request_method :String,show_err:bool =true,error_notify :bool = false,
			append = null,failCal = Callable()):
	remove_child(request_http)
	if request_object == null or request_method.is_empty() or request_object.is_queued_for_deletion() : return
	var data = parse_download_file_result(result,_response_code,body,show_err)
	if data == null and not error_notify : 
		failCal.call()
		return
	var _err = connect("result_data",Callable(request_object,request_method).bind(),CONNECT_ONE_SHOT)
	emit_signal("result_data",data,append,_response_code)
		
func parse_download_file_result(result: int, _response_code: int, body: PackedByteArray,_show_err:bool =true) :
	if(result != HTTPRequest.RESULT_SUCCESS || _response_code !=200 ):
		print_debug("HTTPRequest download_file error result : ",result," _response_code : ",_response_code)
		return null
	else : return body

func upload(token:String,data: PackedByteArray= [],key:String = "",object:Object =null,completed :String = "",
			show_err:bool =true,error_notify :bool = false ) -> HTTPRequest:

	var request = HTTPRequest.new()
	request.use_threads = true
	request.max_redirects = MAX_REDIRECTS
	if object !=null and not completed.is_empty() :
		request.connect("request_completed",Callable(self,"upload_completed").bind(request,object,completed,show_err,error_notify),CONNECT_ONE_SHOT)
	add_child(request)
	var filename = key if (key != "") else "?"
	var file_content :PackedByteArray = data 
		
	var body = PackedByteArray()
	body.append_array(DASHDASH)
	body.append_array(boundary)
	body.append_array(CRLF)
	body.append_array("Content-Disposition".to_utf8_buffer())
	body.append_array(COLONSPACE)
	body.append_array("form-data; name=".to_utf8_buffer())
	body.append_array("\"file\"".to_utf8_buffer())
	body.append_array("; filename=".to_utf8_buffer())
	body.append_array("\"".to_utf8_buffer())
	body.append_array(filename.to_utf8_buffer())
	body.append_array("\"".to_utf8_buffer())
	body.append_array(CRLF)
	body.append_array("Content-Type".to_utf8_buffer())
	body.append_array(COLONSPACE)
	body.append_array("application/octet-stream".to_utf8_buffer())
	body.append_array(CRLF)
	body.append_array("Content-Length".to_utf8_buffer())
	body.append_array(COLONSPACE)
	body.append_array(str(file_content.size()).to_utf8_buffer())
	body.append_array(CRLF)
	body.append_array(CRLF)
	body.append_array(file_content)
	body.append_array(CRLF)
	
	body.append_array(DASHDASH)
	body.append_array(boundary)
	body.append_array(CRLF)
	
	body.append_array("Content-Disposition".to_utf8_buffer())
	body.append_array(COLONSPACE)
	body.append_array("form-data; name=".to_utf8_buffer())
	body.append_array("\"token\"".to_utf8_buffer())
	body.append_array(CRLF)
	body.append_array("Content-Length".to_utf8_buffer())
	body.append_array(COLONSPACE)
	body.append_array(str(token.to_utf8_buffer().size()).to_utf8_buffer())
	body.append_array(CRLF)
	body.append_array(CRLF)
	body.append_array(token.to_utf8_buffer())
	body.append_array(CRLF)

	body.append_array(DASHDASH)
	body.append_array(boundary)
	body.append_array(DASHDASH)
	body.append_array(CRLF)
	
	var headers = [
		"Host: upload-z1.qiniup.com",
		"Content-Type: multipart/form-data; boundary=WebKitFormBoundaryePkpFF7tjBAqx29L",
		"Content-Length: "+str(body.size()),
		"Connection: keep-alive",
		"Accept-Encoding	: gzip"
		]

	var error = request.request_raw("http://upload-z1.qiniup.com" ,headers,HTTPClient.METHOD_POST,body)
	if error != OK:
		print_debug("An error occurred in the HTTP request.")
	return request

func upload_completed(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray,
			request_http:Node,request_object:Object,request_method :String,show_err:bool =true,error_notify :bool = false):
	remove_child(request_http)
	if request_object == null or request_method.is_empty() or request_object.is_queued_for_deletion() : return
	var data = parse_upload_result(result,_response_code,body,show_err)
	if data == null and not error_notify : return
	var _err = connect("result_data",Callable(request_object,request_method).bind(),CONNECT_ONE_SHOT)
	emit_signal("result_data",data)

func parse_upload_result(result: int, _response_code: int, body: PackedByteArray,_show_err:bool =true) :
	if(result != HTTPRequest.RESULT_SUCCESS || _response_code !=200 ):
		print_debug("HTTPRequest upload error result : ",result," _response_code : ",_response_code)
		return null
	var json = JsonWrapper.convertJson(body.get_string_from_utf8())
	return json.key
