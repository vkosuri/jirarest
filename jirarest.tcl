
# ############################################################################
# Jira Utitlities <br />
# @autor Mallikarjunarao Kosuri
# @contact venkatamallikarjunarao.kosuri@adtran.com
# @copyrights www.adtran.com
# @version 1.0 <br />
# ###########################################################################

package provide jira 1.0

package require http
package require base64
package require json

namespace eval ::jira {
    variable baseUrl
	variable headers
}

# ############################################################################
# This procedure will get current header saved into
# @return current headers
# ###########################################################################

proc ::jira::getHeaders { } {
	variable headers
	return $headers
}

# ############################################################################
# This procedure will save current headers into list
# @param header - HTTP header type
# @param headerValue - HTTP header value
# @return void
# ###########################################################################
proc ::jira::setHeaders {header headerValue} {
	variable headers
	lappend headers $header $headerValue
}

# ############################################################################
# This procedure will clear saved headers
# @return void
# ###########################################################################
proc ::jira::clearHeaders {} {
	variable headers
	set headers ""
}

# ############################################################################
# This procedure will login into JIRA and saved headers
# @param username - username to login into JIRA
# @param password - password 
# @return void
# ###########################################################################
proc ::jira::login {jiraurl username password} {
    variable baseUrl
    set baseUrl $jiraurl
	set auth "Basic [base64::encode $username:$password]"
	::jira::setHeaders "Authorization" $auth
	::jira::setHeaders "Content-Type" "application/json"
	::jira::setHeaders "Referer" $baseUrl
	set loginUrl [concat $baseUrl/login.jsp]
	set token [::http::geturl $loginUrl -headers [array get Headers]]
	::jira::setHeaders "Cookie" [dict get [::http::meta $token] Set-Cookie]
}

# ############################################################################
# This procedure will return JIRA PVT Attachment content
# @param jiraId - Jira Identifier
# @return content of pvt attachment
# ###########################################################################
proc ::jira::getJiraAttachement {jiraId jiraFileName} {
    variable baseUrl
    set fileUrl ""
	set headers [::jira::getHeaders]
	array set Headers $headers
	set url [concat $baseUrl/rest/api/2/issue/$jiraId]
    # puts $url
	set token [::http::geturl $url -headers [array get Headers]]
    # puts [::http::data $token]
	set jiraAttachments [dict get [dict get [::json::json2dict [::http::data $token]] fields] attachment]
    # puts $jiraAttachments
	regsub -all {filename\s+} [regexp -all -inline {filename \S+} $jiraAttachments] "" filenameList
	regsub -all {id\s+} [regexp -all -inline {id \d+} $jiraAttachments] "" idList
	regsub -all {content\s+} [regexp -all -inline {content \S+} $jiraAttachments] "" contentList
	foreach name $filenameList id $idList {
		if {[regexp -all $jiraFileName $name]} {
			set fileUrl [concat $baseUrl/secure/attachment/$id/$name]
		}
	}
	set Headers(Content-Type) "application/octet-stream"
	::http::cleanup $token
	set token [::http::geturl $fileUrl -headers [array get Headers]]
	return [::http::data $token]
}

# ############################################################################
# This procedure will add comment given jira identifier
# @param jiraId - JIRA identifier
# @param comment - A comment will add a comment given JIRA
# @return current headers
# ###########################################################################
proc ::jira::addCommentToJira {jiraId comment} {
    variable baseUrl
	set headers [::jira::getHeaders]
	array set Headers $headers
	set comment [concat \{\"body\"\: \"$comment\"\}]
	set url [concat $baseUrl/rest/api/2/issue/$jiraId/comment"]
	set token [::http::geturl $url -query "$comment" -headers [array get Headers] -method POST]
	return [::http::ncode $token]
}

