.pragma library

var api_url = "https://cloud.3dprinteros.com/apiglobal/"
//var api_url = "https://acorn.3dprinteros.com/apiglobal/"

function login(username, passwd, callback) {
    var loginUrl = api_url + "login",
        params = "username=" + encodeURIComponent(username) + "&password=" + encodeURIComponent(passwd);

    sendForm(loginUrl, params, callback)
}

function logout(session, callback) {
    var loginUrl = api_url + "logout",
        params = "session=" + session

    sendForm(loginUrl, params, callback);
}

function checkSession(session, callback) {
    var url = api_url + "check_session",
        params = "session=" + session

    sendForm(url, params, callback);
}

function getProjects(session, callback) {
    var url = api_url + "get_projects",
        params = "session=" + session

    sendForm(url, params, callback);
}

function getPrinterTypes(session, callback) {
    var url = api_url + "get_printer_types",
        params = "session=" + session

    sendForm(url, params, callback);
}

function updateFile(session, fileId, ptype, gtype, zip, callback) {
    var url = api_url + "file_update",
       params = 'session=' + session + '&updates[' + fileId + '][ptype]=' +  parseInt(ptype)
                                                         + '&updates[' + fileId + '][gtype]=' +  gtype 
                                                         + '&updates[' + fileId + '][zip]=' +  zip
    sendForm(url, params, callback);
}

function getAuthToken(session, callback) {
    var url = api_url + "generate_auth_token",
        params = "session=" + session

    sendForm(url, params, callback);
}

function sendForm(url, params, callback) {
    var http = new XMLHttpRequest()
    http.open("POST", url, true)

    // Send the proper header information along with the request
    http.setRequestHeader("Content-type", "application/x-www-form-urlencoded")
    http.setRequestHeader("Content-length", params.length)
    http.setRequestHeader("Connection", "close")

    http.onreadystatechange = function(data) {
        var response
        if (http.readyState === XMLHttpRequest.DONE) {
            response = (http.status === 200)
            ? JSON.parse(http.responseText)
            : JSON.parse('{ "result": false, "message": ' + http.status +  '}')

            callback(response)
        }
    }

    http.send(params);
}
