ruleset twilioModule {
  meta {
    configure using account_sid = ""
                    auth_token = ""
    provides
        send_sms, messages
  }
 
  global {
    send_sms = defaction(to, from, message) {
       base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>
       http:post(base_url + "Messages.json", form = {
                "From":from,
                "To":to,
                "Body":message
            })
    }

    messages = function(to, from, pageSize) {
       to = (to == "") => NULL | to;
       from = (from == "") => NULL | from;
       pageSize = (pageSize == "") => NULL | pageSize;
       base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>;
       http:get(base_url + "Messages.json", qs = {
           "To":to,
           "From":from,
           "PageSize":pageSize
       }){"content"}.decode()
    }
  }
}