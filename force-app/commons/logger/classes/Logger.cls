/**
* MIT License
*
* Copyright (c) 2019 Piotr Kożuchowski
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

/**
 * Logs persistent messages in custom object records and emits platform event.
 *
 * @dependency core/Apex
 */
public with sharing class Logger {
    private Boolean immediate;
    private List<Log__c> logs = new List<Log__c>();

    /**
     * Default constructor works in immediate mode.
     * This is preferred mode for controllers and async apex.
     */
    public Logger() {
        this(true);
    }

    /**
     * @param immediate If true, flushes logs immediately after logging action.
     * Immediate mode is preferred in situation of multiple subsequent callouts
     * and when you want to reuse one logger (trigger?)
     */
    public Logger(Boolean immediate) {
        this.immediate = immediate;
    }

    /**
     * Logs message with INFO logging level
     */
    public void info(String message) {
        log(LoggingLevel.INFO, message);
    }
    public void info(Log__c log) {
        log(LoggingLevel.INFO, log);
    }


    /**
     * Logs message with WARNING logging level
     */
    public void warn(String message) {
        log(LoggingLevel.WARN, message);
    }
    public void warn(Log__c log) {
        log(LoggingLevel.WARN, log);
    }


    /**
     * Logs message with WARNING logging level
     */
    public void error(String message) {
        log(LoggingLevel.ERROR, message);
    }
    public void error(Log__c log) {
        log(LoggingLevel.ERROR, log);
    }
    public void error(Exception ex) {
        log(LoggingLevel.ERROR, ex, null);
    }
    public void error(Exception ex, Id referenceId) {
        log(LoggingLevel.ERROR, ex, referenceId);
    }


    /**
     * Logs message with given logging level
     */
    public void log(LoggingLevel loggingLevel, String message) {
        log(loggingLevel, new Log__c(
                Message__c = message
        ));
    }

    /**
     * Logs exception with given logging level
     */
    public void log(LoggingLevel loggingLevel, Exception ex, Id referenceId) {
        log(loggingLevel, new Log__c(
                Message__c = ex.getMessage()
                        + '\n\n'
                        + ex.getStackTraceString()
                        + (ex.getCause() != null ? ('\nCause:' + ex.getCause().getMessage() + '\n\n' + ex.getCause().getStackTraceString()) : ''),
                ReferenceId__c = referenceId
        ));
    }

    /**
     * Logs log object with given logging level
     */
    public void log(LoggingLevel loggingLevel, Log__c log) {
        if (LoggingSettings.shouldCreateLog(loggingLevel)) {
            log.ApexClass__c = getApexClass();
            log.LoggingLevel__c = loggingLevel.name();
            logs.add(log);

            if (immediate) {
                flush();
            }
        }
    }


    /**
     * Publishes all recorded logs and clears log buffer.
     * When logging is done in-between callouts, flush should be made after all callouts are finished.
     *
     * Logs are translated to Platform Event and then back from events to records to maintain logs created before unhandled exception.
     * This is mainly for AuraEnabled methods which may have to throw AuraHandledException for proper aura handling,
     * but would not be able to save logs under normal circumstances.
     */
    public void flush() {
        List<LoggingEvent__e> loggingEvents = new List<LoggingEvent__e>();

        for (Log__c log : logs) {
            loggingEvents.add(new LoggingEvent__e(
                    ApexClass__c = log.ApexClass__c,
                    LoggingLevel__c = log.LoggingLevel__c,
                    Message__c = log.Message__c,
                    ReferenceId__c = log.ReferenceId__c,
                    UserId__c = UserInfo.getUserId()
            ));
        }

        EventBus.publish(loggingEvents);
        logs.clear();
    }


    /**
     * @return Name of the first class in stack trace which is not Logger.
     */
    private String getApexClass() {
        List<Apex.StackTraceLine> stackTraceLines = Apex.getStackTrace();

        for (Integer i = 0; i < stackTraceLines.size(); i++) {
            if (stackTraceLines[i].apexClass != 'Logger') {
                return stackTraceLines[i].method;
            }
        }

        return '';
    }
}