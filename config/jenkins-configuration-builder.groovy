#!/usr/bin/env groovy

//read config and create helper files in generated folder
def config = new ConfigSlurper().parse(new File('Configuration.groovy').toURL())
config.each { key, value ->
  File file = new File("./generated/$key")
  if (value instanceof List) {
    file.text = ""
    value.each { item ->
       file << "$item\n"
    }
    println "DEBUG: $key --> $value (List)"
  } else {
    file.text = "$value"
    println "DEBUG: $key --> $value"
  }
}