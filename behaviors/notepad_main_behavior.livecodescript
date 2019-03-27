script "notepad_main_behavior"
//>GLOBALS
global gNoteA, gSelectedNote

on preOpenCard
     refreshNotesList
     if gSelectedNote <> empty then editNote gSelectedNote
end preOpenCard



private function _____MOUSE_KEY
end _____MOUSE_KEY
on mouseUp
     cs_postMaster_mouseUp
end mouseUp


on rawKeyDown pKey
     local tOwner, tControls
     
     put the childControlNames of grp "sidebar" of stack "notepad" into tControls
     
     if pKey is 65309 then //mouse wheel up
          if the short name of the owner of the owner of the target = "sidebar" and the number of lines of tControls > 5 then
               set the vScroll of grp "sidebar" of stack "notepad" to the vScroll of grp "sidebar" of stack "notepad" - 7
          else if the short name of the owner of the target = "current note" then
               set the vScroll of fld "note data field" of grp "current note" of stack "notepad" to the vScroll of fld "note data field" of grp "current note" of stack "notepad" - 7
          end if
     else if pKey is 65308 then //mouse wheel down
          if the short name of the owner of the owner of the target = "sidebar" and the number of lines of tControls > 5 then
               set the vScroll of grp "sidebar" of stack "notepad" to the vScroll of grp "sidebar" of stack "notepad" + 7
          else if the short name of the owner of the target = "current note" then
               set the vScroll of fld "note data field" of grp "current note" of stack "notepad" to the vScroll of fld "note data field" of grp "current note" of stack "notepad" + 7
          end if
     else
          pass rawKeyDown
     end if
end rawKeyDown



private function _____CARD_CODE
end _____CARD_CODE
command cs_postMaster_mouseUp
     local tOwner
     
     if the short name of the target is "main" then exit cs_postMaster_mouseUp
     put the short name of the owner of the target into tOwner
     
     if tOwner = "header" then
          switch the short name of the target
               case "add"
                    createNote
                    redrawSidebar
                    break
                    
               case "delete"
                    deleteNote
                    redrawSidebar
                    break
                    
               case "save"
                    updateNote
                    redrawSidebar
                    break
          end switch
     else
          if the short name of the owner of the owner of the target = "sidebar" then
               put tOwner into gSelectedNote
               editNote gSelectedNote
               lock screen
               if gNoteA is empty then
                    answer "Error reading the note."
               else
                    hiliteNote
                    put gNoteA[the keys of gNoteA]["title"] into fld "note title field" of grp "current note" of stack "notepad"
                    put gNoteA[the keys of gNoteA]["data"] into fld "note data field" of grp "current note" of stack "notepad"
               end if
               unlock screen
          end if
     end if
end cs_postMaster_mouseUp



private function _____HELPERS
end _____HELPERS
command createNote
     local tDataA, tTable, tTarget, tRecordID
     
     put empty into fld "note title field" of stack "notepad"
     put empty into fld "note data field" of stack "notepad"
     
     //SET UP FOR CDB_CREATE
     //Input the values into each key
     put "New Note" into tDataA["title"]
     put the milliseconds into tDataA["timestamp"]
     put empty into tDataA["data"]
     
     //Specify the table
     put "notes" into tTable
     
     //Specify the target
     put "local" into tTarget
     
     //Create the note
     put cdb_create(tDataA,tTable,tTarget) into tRecordID
     
     //ADD NOTE TO SIDEBAR
     addNoteToSidebar tRecordID, tDataA["title"], tDataA["timestamp"]
     
     put tRecordID into gSelectedNote
     editNote gSelectedNote
end createNote


function getNotes
     local tTable, tRecordIDs, tTarget, tOutputA
     
     //READ ALL NOTES USING '*' TO INDICATE ALL RECORDS IN TABLE
     put "*" into tRecordIDs
     
     //Specify the table
     put "notes" into tTable
     
     //Specify the target
     put "local" into tTarget
     
     //Read record
     put cdb_read(tTable,tRecordIDs,tTarget) into tOutputA
     
     return tOutputA
end getNotes


command editNote pRecordID
     local tTable, tRecordIDs, tTarget
     
     //Clear recent note
     put empty into gNoteA
     
     //SET UP FOR CDB_READ
     put pRecordID into tRecordIDs
     
     //Specify the table
     put "notes" into tTable
     
     //Specify the target
     put "local" into tTarget
     
     //Read the note and put it into gNoteA
     put cdb_read(tTable,tRecordIDs,tTarget) into gNoteA
end editNote


command updateNote
     local tDataA, tTable, tRecordID, tTarget
     
     put the keys of gNoteA into tRecordID
     
     //SET UP FOR CDB_UPDATE
     
     //Specify the table
     put "notes" into tTable
     
     //Specify the target
     put "local" into tTarget
     
     //Input updated values into each key
     put fld "note title field" of grp "current note" of stack "notepad" into tDataA["title"]
     put the milliseconds into tDataA["timestamp"]
     put fld "note data field" of grp "current note" of stack "notepad" into tDataA["data"]
     
     //Update the note
     cdb_update tDataA, tTable, tRecordID, tTarget
     
     //UPDATE SIDEBAR
     updateNoteInSidebar tRecordID, tDataA["title"], tDataA["timestamp"]
end updateNote


command deleteNote
     local tTable, tRecordID, tTarget
     
     //SET UP FOR CDB_DELETE
     put gSelectedNote into tRecordID
     
     //Specify the table
     put "notes" into tTable
     
     //Specify the target
     put "local" into tTarget
     
     //Delete the note locally
     cdb_delete tTable, tRecordID, tTarget
     
     //DELETE NOTE FROM SIDEBAR
     delete grp tRecordID of grp "sidebar" of stack "notepad"
end deleteNote


command addNoteToSidebar pRecordID, pTitle, pTimestamp
     local tNewGroup, tTime, tPreview
     
     copy grp "note template" of stack "notepad" to grp "sidebar" of stack "notepad"
     put it into tNewGroup
     
     put char 1 to -4 of pTimestamp into tTime
     convert tTime to short system time
     put pTitle && tTime into tPreview
     set the name of tNewGroup to pRecordID
     put pRecordID into tNewGroup
     put tPreview into fld "note description" of grp tNewGroup of stack "notepad"
     set the vis of grp tNewGroup to true
end addNoteToSidebar


command updateNoteInSidebar pRecordID, pTitle, pTimestamp
     local tTime, tPreview
     
     put char 1 to -4 of pTimestamp into tTime
     convert tTime to short system time
     put pTitle && tTime into tPreview
     put tPreview into fld "note description" of grp pRecordID of grp "sidebar" of stack "notepad"
end updateNoteInSidebar


command redrawSidebar
     local tNotesA, tNotes, tRecordID, tPreviousLine, tTime, tBottom
     
     put getNotes() into tNotesA
     
     if tNotesA <> empty then
          repeat for each key xNote in tNotesA
               put xNote && tNotesA[xNote]["timestamp"] & lf after tNotes
          end repeat
          set the itemDel to " "
          sort lines of tNotes descending numeric by item 2 of each
          put item 1 of line 1 of tNotes into gSelectedNote
          
          lock screen
          repeat with xLine = 1 to the number of lines in tNotes
               put item 1 of line xLine of tNotes into tRecordID
               if tRecordID = gSelectedNote then
                    set the top of grp tRecordID of grp "sidebar" of stack "notepad" to the bottom of grc "header backdrop" of grp "header" of stack "notepad" - 5
                    set the left of grp tRecordID of grp "sidebar" of stack "notepad" to the left of grc "header backdrop" of grp "header" of stack "notepad" - 6
               else
                    put item 1 of line (xLine - 1) of tNotes into tPreviousLine
                    set the top of grp tRecordID of grp "sidebar" of stack "notepad" to the bottom of grp tPreviousLine of grp "sidebar" of stack "notepad" - 9
                    set the left of grp tRecordID of grp "sidebar" of stack "notepad" to the left of grp tPreviousLine of grp "sidebar" of stack "notepad"
               end if
               
               put char 1 to -4 of tNotesA[tRecordID]["timestamp"] into tTime
               convert tTime to short system time
               put tNotesA[tRecordID]["title"] && tTime into fld "note description" of grp tRecordID of grp "sidebar" of stack "notepad"
          end repeat
          
          hiliteNote
          put tNotesA[gSelectedNote]["title"] into fld "note title field" of grp "current note" of stack "notepad"
          put tNotesA[gSelectedNote]["data"] into fld "note data field" of grp "current note" of stack "notepad"
          set the vis of grp "current note" of stack "notepad" to true
          set the vis of widget "delete" of grp "header" of stack "notepad" to true
          set the vis of widget "save" of grp "header" of stack "notepad" to true
          
          if the number of elements of tNotesA > 5 then
               put (the height of grc "note backdrop" of grp "note template" of stack "notepad" - 6) * (the number of elements of tNotesA - 5) + the bottom of grp "sidebar" of stack "notepad" into tBottom
               set the boundingRect of grp "sidebar" of stack "notepad" to -6,38,320,tBottom
               set the vScrollbar of grp "sidebar" of stack "notepad" to true
          else
               set the boundingRect of grp "sidebar" of stack "notepad" to empty
               set the vScrollbar of grp "sidebar" of stack "notepad" to false
          end if
          unlock screen
     else
          lock screen
          put empty into fld "note title field" of grp "current note" of stack "notepad"
          put empty into fld "note data field" of grp "current note" of stack "notepad"
          set the vis of grp "current note" of stack "notepad" to false
          set the vis of widget "delete" of grp "header" of stack "notepad" to false
          set the vis of widget "save" of grp "header" of stack "notepad" to false
          set the vScrollbar of grp "sidebar" of stack "notepad" to false
          set the boundingRect of grp "sidebar" of stack "notepad" to empty
          unlock screen
     end if
end redrawSidebar
     
     
command hiliteNote
     local tControls

     put the childControlNames of grp "sidebar" into tControls
     repeat for each line xLine in tControls
          set the blendLevel of grc "note backdrop" of grp xLine of grp "sidebar" of stack "notepad" to "80"
     end repeat
     
     set the blendLevel of grc "note backdrop" of grp gSelectedNote of grp "sidebar" of stack "notepad" to "40"
end hiliteNote


command refreshNotesList
     local tNotesA
     
     put getNotes() into tNotesA
     
     lock screen
     if tNotesA is empty then
          set the vis of grp "current note" of stack "notepad" to false
          set the vis of widget "delete" of grp "header" of stack "notepad" to false
          set the vis of widget "save" of grp "header" of stack "notepad" to false
          set the vScrollbar of grp "sidebar" of stack "notepad" to false
     else
          redrawSidebar
          set the vis of grp "current note" of stack "notepad" to true
          set the vis of widget "delete" of grp "header" of stack "notepad" to true
          set the vis of widget "save" of grp "header" of stack "notepad" to true
          if the number of elements of tNotesA > 5 then set the vScrollbar of grp "sidebar" of stack "notepad" to true
     end if
     unlock screen
end refreshNotesList
