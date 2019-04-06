window.config = {
  "server_host": "localhost:8080",
  "protocol": "http://",
  "default_eci": "KJRBQwQSXJ4bWZMV4gcap",

  //ruleset name where you are storing data
  "temp_store_rid": "temperature_store",
  //in the above ruleset, what function returns an array of temperature objects?
  "temperature_func": "temperatures",

  "violation_func": "threshold_violations",
  "profile_rid": "sensor_profile",
  "profile_func": "get_all"
};
