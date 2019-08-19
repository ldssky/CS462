window.config = {
  "server_host": "localhost:8080",
  "protocol": "http://",
  "default_eci": "zm3xzwsvUQMMaxjQRvNj7",

  //ruleset name where you are storing data
  "temp_store_rid": "temperature_store",
  //in the above ruleset, what function returns an array of temperature objects?
  "temperature_func": "temperatures",

  //ruleset name where you are storing eci data
  "eci_store_rid": "manage_sensors",
  //in the above ruleset, what function returns the eci you are looking for?
  "eci_func": "get_current_eci",
  //in the above ruleset, what function adds a sensor?
  "add_sensor_func": "new_sensor",
  //in the above ruleset, what function deletes a sensor?
  "delete_sensor_func": "delete_sensor",

  "violation_func": "threshold_violations",
  "profile_rid": "sensor_profile",
  "profile_func": "get_all"
};
