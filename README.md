# procExecLog
Run your dos/windows proccess with full traceability

## how to run
```
c:\> \procExecLog\procExecLog.bat "My Description" dir /s /r c:\
20201018 220309 20201018 220706 SUCCESS 0 dir "My Description" "dir /s /r c:\" ""
```

## traceability

To full traceability the scrip write log information in this channels:

* log file. `\procExecLog\log\dir-20201018.log`
* slack. See session slack config.
* event viewer. Need user permission to write event viewer errors.

## slack config

To sent slack message you need:

* [curl for windows](https://curl.haxx.se/windows/)
    * unpack zipfile in `procExecLog` dir.
    * the script search `curl\bin\curl.exe` in  `procExecLog` dir.
* create the file `config-slack.bat` with the sample: 
    ```bat
    :: slack parameters config

    :: - slack webhook url
    SET SLACK_URL=https://hooks.slack.com/services/FFFFFFFFF/aaaaaaaaa/cccccccccccccccccccccccc
    :: - notification icon
    SET SLACK_ICON=:computer:
    :: - success icon
    SET SLACK_SUCCESS=:sunrise:
    :: - error icon
    SET SLACK_ERROR=:bomb:
    :: - otification channel
    SET SLACK_CHANNEL=#sandbox
    ```