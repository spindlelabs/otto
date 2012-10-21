package com.spindle.otto.helloworld

import org.slf4j.LoggerFactory
import java.util.concurrent.TimeUnit

object Main {
  private val logger = LoggerFactory.getLogger(getClass)

  def main(args: Array[String]) {
    logger.trace("Logging at trace level")
    logger.debug("Logging at debug level")
    logger.info("Logging at info level")

    logger.info("Sleeping for 30 seconds and then exiting to simulate an application crash")
    TimeUnit.SECONDS.sleep(30)
    logger.info("Exiting to simulate an application crash")
  }
}
