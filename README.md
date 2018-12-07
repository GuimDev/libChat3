libChat3
=============

[![Esoui libChat3 page](https://img.shields.io/badge/esoui.com-libChat3-green.svg)](https://www.esoui.com/downloads/info2210-libChat3ProvisionsMurkmireUpdate.html)

libChat3 is a library Chat for The Elder Scrolls Online.

**Use [libGarfield](https://www.esoui.com/downloads/fileinfo.php?id=2209-libGarfieldChatcareforAddOnuseslibChatampplayer.html) to be sure that libChat3 is not overwrite by another addOn.**

### Next update :

 - libChat3.5 will add full support for libChat4 to prepare the transition to libChat4.
 - libChat4 : Break changes, libChat4 will be incompatible with backwards-versions ;

### New in libChat3 :

Allow several addon listeners on one event (without conflict) :
 - registerName
 - registerText
 - registerAppendDDSBeforeAll
 - registerAppendTextBeforeAll
 - registerAppendDDSBeforeSender
 - registerAppendTextBeforeSender
 - registerAppendDDSAfterSender
 - registerAppendTextAfterSender
 - registerAppendDDSBeforeText
 - registerAppendTextBeforeText
 - registerAppendDDSAfterText
 - registerAppendTextAfterText


### AddOn Author  Part :

Event Schema to add text element :

```text
Mini :
|                           message                         |
|   {___1___} | {Sender} | {___2___} | {Text} | {___3___}   |
| BfAll |      playerLink      |        text        | ..... |

Full :
|            |                    ___1___                    | {Sender} |                    ___2___                    | {Text} |                    ___3___                    |
| Position : |   BeforeAll   | {OptEsoFormat} | BeforeSender |          |  AfterSender  | {OptEsoFormat} |  BeforeText  |        |   AfterText   | {OptEsoFormat} | ............ |
| Index :    | DDS_  | Text_ |                | DDS_ | Text_ |          | Text_ | DDS_  |                | DDS_ | Text_ |        | Text_ | DDS_  |                | ............ |
| Variable : |  channelLink  |                |               playerLink                |                |                 text                  |                | ............ |


 *{OptEsoFormat} = {OptionnalESOUIFormat}[/code]
 ```

### How to use :

```lua
local LC = LibStub('libChat-1.0')

-- Replace / Parse the player name :
LC:registerFrom(function(channelID, from, isCustomerService, fromDisplayName) return from end)-- /!\ 4 arguments

-- Replace / Parse the text :
LC:registerText(function(channelID, from, text, isCustomerService, fromDisplayName) return text end)

-- Add text element (watch the schema to get the position name) :
local position = "BeforeAll"
local index = "Text'"
LC:["registerAppend" .. index .. position](function(channelID, from, text, isCustomerService, fromDisplayName) return ">>" end)
```


Old version and How to use : [libChat2](http://www.esoui.com/downloads/info740-libChat2.html).
