package com.spindle.otto.helloworld

import org.slf4j.LoggerFactory
import java.util.concurrent.TimeUnit
import com.typesafe.config._

object Main {
  private val logger = LoggerFactory.getLogger(getClass)

  def main(args: Array[String]) {
    logger.trace("Logging at trace level; edit logback.xml to change the log level")
    logger.debug("Logging at debug level; edit logback.xml to change the log level")
    logger.info("Logging at info level; edit logback.xml to change the log level")

    val config = ConfigFactory.load()
    logger.info("From configuration: " + config.getString("helloworld.text"))

    logger.info("Sleeping for 30 seconds and then exiting to simulate an application crash")
    TimeUnit.SECONDS.sleep(30)
    logger.info("Exiting to simulate an application crash")
  }
}
