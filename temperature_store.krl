ruleset temperature_store {
  meta {
    provides
        temperatures, threshold_violations, inrange_temperatures
    shares temperatures, threshold_violations, inrange_temperatures, __testing
  }

  global {
    temperatures = function() {
      ent:temperatures.defaultsTo([])
    }

    threshold_violations = function() {
       ent:violationTemperatures.defaultsTo([])
    }

    inrange_temperatures = function() {
      ent:temperatures.defaultsTo([]);
      ent:violationTemperatures.defaultsTo([]);
      ent:temperatures.difference(ent:violationTemperatures)
    }

    __testing = { "queries": [ { "name": "temperatures" },
                               { "name": "threshold_violations" },
                               { "name": "inrange_temperatures" },
                               { "name": "__testing" } ],
                  "events": [ { "domain": "sensor", "type": "reading_reset" } ] }
  }

  rule collect_temperatures {
    select when wovyn new_temperature_reading
      pre {
        temperature = event:attr("temperature")[0]{"temperatureF"}.klog("temperatureF is ");
        timestamp = event:attr("timestamp").klog("timestamp is ");
      }
      send_directive("collect_temperatures", {"temperature":temperature});
      always {
        ent:temperatures := ent:temperatures.defaultsTo([]).append([{"time":timestamp, "temperature": temperature}])
      }
  }

  rule collect_threshold_violations {
    select when wovyn threshold_violation
    pre {
      violationTemperature = event:attr("temperature")[0]{"temperatureF"}.klog("temperatureF is ");
      timestamp = event:attr("timestamp").klog("timestamp is ");
    }
    send_directive("collect_threshold_violations", {"threshold violation temperature":violationTemperature});
    always {
      ent:violationTemperatures := ent:violationTemperatures.defaultsTo([]).append([{"time":timestamp, "temperature": violationTemperature}])
    }
  }

  rule clear_temperatures {
    select when sensor reading_reset
    send_directive("clear_temperatures", {"clearing all temperatures":"complete"});
    always {
      clear ent:temperatures;
      clear ent:violationTemperatures
    }
  }

}