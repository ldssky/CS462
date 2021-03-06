ruleset manage_sensors {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subscription
    provides
        get_current_eci, showChildren, get_current_eci, sensors, callTemperaturesInEachSensor, callTemperatureTest
    shares __testing, showChildren, get_current_eci, sensors, callTemperaturesInEachSensor, callTemperatureTest
  }

  global {

    temperature_threshold = 50
    SMS_number = "13185370837"

    get_current_eci = function() {
      x = ent:sensors;
      x.defaultsTo([{"sensor_name":"default_sensor_name", "eci":"zm3xzwsvUQMMaxjQRvNj7"}])
    }

    sensorSubscriptions = function() {
      sensorSubscriptions = subscription:established("Tx_role", "sensor");
      sensorSubscriptions
    }

    sensors = function() {
      ent:sensorPicos
    }

    showChildren = function() {
      wrangler:children()
    }

    callTemperaturesInEachSensor = function() {
      ent:sensorPicos.map(function(x) {
        {}.put([x.get(["sensor_name"])], wrangler:skyQuery(x.get(["eci"]), "temperature_store", "temperatures", {}))
      })
    }

    callTemperatureTest = function () {
      json = ent:sensors.map(function(x) {
        y = x.get(["eci"]);
        wrangler:skyQuery(y, "temperature_store", "temperatures", {});
      });
      json
    }

    __testing = { "queries": [ { "name": "showChildren", "args": [ ] },
                               { "name": "sensors", "args": [ ] },
                               { "name": "get_current_eci", "args": [ ] },
                               { "name": "callTemperaturesInEachSensor", "args": [ ] },
                               { "name": "callTemperatureTest", "args": [ ] } ], 
                  "events":  [ { "domain": "sensor", "type": "new_sensor", "attrs": 
                                [ "sensor_name" ] },
                               { "domain": "collection", "type": "empty", "attrs": [ ] },
                               { "domain": "sensor", "type": "unneeded_sensor", "attrs": [ "sensor_name" ] },
                               { "domain": "introduce", "type": "sensor", "attrs": [ "eci", "name", "host" ] } ] }

  }

  rule collection_empty {
    select when collection empty
    always {
      ent:sensors := {}
    }
  }

  rule new_sensor {
    select when sensor new_sensor
    pre {
      sensor_name = event:attr("sensor_name")
      exists = ent:sensors >< sensor_name
    }
    if exists then
      send_directive("sensor_ready", {"sensor_name":sensor_name})
    notfired {
      raise wrangler event "child_creation"
        attributes { "name": sensor_name, "color": "#ffff00", "rids": ["temperature_store", "wovyn_base", "sensor_profile"] };
    }
  }

  rule update_child_profile {
   select when wrangler new_child_created
     pre {
       attributes = event:attrs.klog("wrangler new_child_created attributes are")
       sensor_name = event:attr("name").klog("wrangler new_child_created name attribute is ")
       eci = event:attr("eci").klog("wrangler new_child_created eci is ")
     }
     event:send({"eci":eci, "domain":"sensor", "type":"profile_updated", "attrs":{"new_sensor_name": sensor_name, "new_threshold": temperature_threshold, "new_send_to": SMS_number}})
  }

  rule store_new_sensor {
    select when wrangler child_initialized
    pre {
      attributes = event:attrs.klog("store_new_sensor attributes are ")
      rsattributes = event:attr("rs_attrs").klog("store_new_sensor rs attributes are ")
      sensor_name = event:attr("rs_attrs"){"name"}
      eci = event:attr("eci").klog("eci of stored new sensor is ")
    }
    if sensor_name.klog("found sensor_name")
    then
      noop()
    fired {
      ent:sensors := ent:sensors.defaultsTo([]).append([{"sensor_name":sensor_name, "eci":eci}]);
    }
  }

  rule subscribeSensorToParent {
    select when wrangler child_initialized
    pre {
      attributes = event:attrs.klog("subscribeSensorToParent attributes are ")
      childPicoName = event:attr("name").klog("childPicoName is ")
      parentEci = event:attr("parent_eci").klog("parentEci is ")
      newChildID = event:attr("id").klog("newChildID is ")
      eci = event:attr("eci").klog("eci is ")
      rids = event:attr("rids").klog("rids are ")
      rids_to_install = event:attr("rids_to_install").klog("rids_to_install are ")
    }
    if rids.any(function(x){x == "temperature_store"}) && rids.any(function(x){x == "wovyn_base"}) && rids.any(function(x){x == "sensor_profile"}) then
      event:send({"eci":eci, "domain":"wrangler", "type":"subscription", "attrs":{
         "name" : childPicoName,
         "Rx_role": "sensor",
         "Tx_role": "manager",
         "channel_type": "subscription",
         "wellKnown_Tx" : parentEci
       }})
  }

  rule acceptSensorSubscriptions {
    select when wrangler inbound_pending_subscription_added
    always {
      raise wrangler event "pending_subscription_approval" attributes event:attrs;
    }
  }

  rule querySensorSubscriptionForSensor {
    select when wrangler subscription_added
    pre {
      isSensor = event:attr("Rx_role") == "sensor" || event:attr("Tx_role") == "sensor"
    }
    if isSensor then
      noop()
    fired {
      subcriptionID = event:attr("Id");
      subscriptionArray = subscription:established("Id", subcriptionID);
      subcription = subscriptionArray.head();
      peerChannel = subcription{"Tx"};
      peerHost = (subcription{"Tx_host"} || meta:host);
      peerInfo = wrangler:skyQuery(peerChannel, "io.picolabs.wrangler", "myself", null, peerHost).klog("peerInfo is ");
      peerPicoName = peerInfo{"name"}.klog("pico name is");
      peerPicoEci = peerInfo{"eci"}.klog("eci is ");
      ent:sensorPicos := ent:sensorPicos.defaultsTo([]).append([{"sensor_name":peerPicoName, "eci":peerPicoEci}]);
    }
  }

  rule introduceSensor {
    select when introduce sensor
    pre {
      attributes = event:attrs.klog("introduce sensor attributes are ")
      sensorEci = event:attr("eci")
      sensorName = event:attr("name")
      sensorHost = event:attr("host")
    }
    always {
      raise wrangler event "subscription"
        attributes {
          "name": sensorName,
          "Rx_role": "manager",
          "Tx_role": "sensor",
          "channel_type": "subscription",
          "wellKnown_Tx": sensorEci,
          "Tx_host": sensorHost };
    }
  }

  rule delete_sensor {
    select when sensor unneeded_sensor
    pre {
      sensor_name = event:attr("sensor_name")
      exists = ent:sensors.any(function(x){
        x{["sensor_name"]} == sensor_name
      })
    }
    if exists then
      send_directive("deleting_sensor", {"sensor_name":sensor_name})
    fired {
      raise wrangler event "child_deletion"
        attributes {"name": sensor_name};
      ent:sensors := ent:sensors.filter(function(x){
        x{["sensor_name"]} != sensor_name
      });
    }
  }

}