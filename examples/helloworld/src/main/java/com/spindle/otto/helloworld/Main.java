package com.spindle.otto.helloworld;

import com.typesafe.config.Config;
import com.typesafe.config.ConfigFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.TimeUnit;

public final class Main {

    private final static Logger logger = LoggerFactory.getLogger(Main.class);

    public static void main(String[] args) throws InterruptedException {
        logger.trace("Logging at trace level; edit logback.xml to change the log level");
        logger.debug("Logging at debug level; edit logback.xml to change the log level");
        logger.info("Logging at info level; edit logback.xml to change the log level");

        Config config = ConfigFactory.load();
        logger.info("Configuration value1: " + config.getString("helloworld.value1"));
        logger.info("Configuration value2: " + config.getString("helloworld.value2"));
        logger.info("Configuration value3: " + config.getString("helloworld.value3"));

        logger.info("Sleeping for 30 seconds and then exiting to simulate an application crash");
        TimeUnit.SECONDS.sleep(30);
        logger.info("Exiting to simulate an application crash");
    }
}
