ruleset wovyn_base {
  meta {
    use module keyModule
    use module twilioModule alias twilio
        with account_sid = keys:twilio{"account_sid"}
             auth_token =  keys:twilio{"auth_token"}
    use module sensor_profile alias profile
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subscription
    shares __testing, get_temperature_threshold, get_SMS_number
  }

  global {
    get_temperature_threshold = function() {
      profile:get_all(){"new_threshold"}.klog("threshold is ")
    }
    get_SMS_number = function () {
      "+" + profile:get_all(){"new_send_to"}.klog("SMS number is ")
    }

    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ { "domain": "wovyn", "type": "heartbeat",
                              "attrs": [ "emitterGUID", "eventDomain", "eventName", "genericThing", "property", "specificThing" ] } ] }
  }
 
  rule process_heartbeat {
    select when wovyn heartbeat where event:attr("genericThing")
    pre {
      attributes = event:attrs.klog("attrs");
    }
    every {
      send_directive("say", {"something":"Heartbeat received"});
    }
    always {
      raise wovyn event "new_temperature_reading" attributes {
        "temperature" : event:attr("genericThing"){["data", "temperature"]},
        "timestamp" : time:now()
      }
    }
  }

  rule find_high_temps {
    select when wovyn new_temperature_reading
    pre {
      attributes = event:attrs.klog("attributes are ");
      temperatureF = event:attr("temperature")[0]{"temperatureF"}.klog("temperatureF is ");
      temperatureThreshold = get_temperature_threshold().klog("get_temperature_threshold is ");
      isHotter = (temperatureF > get_temperature_threshold()) => "yes" | "no";
      tooHot = (temperatureF > get_temperature_threshold());
    }
    every {
      send_directive("say", {"Was there a temperature violation?": isHotter});
    }
    always {
      raise wovyn event "threshold_violation" attributes event:attrs if tooHot;
    }
  }

  rule threshold_notification {
    select when wovyn threshold_violation
      foreach subscription:established("Tx_role", "manager") setting (subscriptionArray)
      pre {
        subcription = subscriptionArray.head();
        peerChannel = subcription{"Tx"};
        peerHost = (subcription{"Tx_host"} || meta:host);
        peerInfo = wrangler:skyQuery(peerChannel, "io.picolabs.wrangler", "myself", null, peerHost).klog("peerInfo is ");
        peerPicoName = peerInfo{"name"}.klog("pico name is");
        peerPicoEci = peerInfo{"eci"}.klog("eci is ");
      }
      event:send({"eci":peerPicoEci, "domain":"wovyn", "type":"threshold_violation", "attrs":{}})
  }

}