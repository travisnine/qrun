OpenConsole() ;console program (no gui)

;parse parameters
paramCount = CountProgramParameters() - 1
If paramCount < 1 ;print usage if we didnt get enough arguments
  PrintN("Usage: qrun program {}")
  End
EndIf
Global commandToRun.s = ProgramParameter() ;first argument is which command to run
Global commandArgs.s = "" ;this will be all the arguments to pass
While paramCount > 0 ;loop until we have proccessed them all
  commandArgs = commandArgs + ~"\"" + ProgramParameter() + ~"\"" ;append the next argument to the arg list
  paramCount = paramCount - 1 ;next
  If paramCount > 0 ;is there any more to do?
    commandArgs = commandArgs + " " ;if there is more to do, add a space between each argument
  EndIf
Wend ;repeat

;show parsed parameters
PrintN("args: " + commandToRun + " " + commandArgs)

;create queue and thread stuff
Global NewList queue.s()
Global qlock = CreateMutex()
Global qsem  = CreateSemaphore()
;main processing thread
Procedure qthread(*value)
  qItem.s = "" ;string to hold current queue item
  Repeat ;loop forever
    WaitSemaphore(qsem) ; wait for signal
    LockMutex(qlock) ;wait for our turn
        If ListSize(queue()) = 0 ;if we got a signal and the list is empty, that is our notice to end the thread
          ProcedureReturn ;exit the thread
        EndIf
        FirstElement(queue()) ;select the top of the stack
        qItem.s = queue() ;get the item
        DeleteElement(queue()) ;remove the top of the stack
    UnlockMutex(qlock) ;done with our turn
    argString.s = ReplaceString(commandArgs,"{}",qItem);replace command args with item from queue
    RunProgram(commandToRun,argString,".",#PB_Program_Wait) ;execute and wait for finish
  ForEver ;repeat
EndProcedure

qthreadid = CreateThread(@qthread(),0) ;start processing thread in background

Repeat ;loop forever
  datain.s = Input() ;read line from standard input
  If datain = #PB_Input_Eof ;if there is nothing left to read (recieved EOF)
    SignalSemaphore(qsem) ;send signal without adding anything to the list
    WaitThread(qthreadid) ;wait for the current queue to finish processing
    End ;exit program
  EndIf
  If datain = "" ;skip blank lines
    Continue
  EndIf
  LockMutex(qlock) ;wait for our turn
      LastElement(queue()) ;goto bottom of the stack
      AddElement(queue()) ;add a new item to the end
      queue() = datain ;set the item to what we got from stdin
  UnlockMutex(qlock) ;done with our turn
  PrintN("Added: " + datain) ;print to stdout that we added it to the queue
  SignalSemaphore(qsem) ; signal the processing thread that queue has a new item
ForEver


; IDE Options = PureBasic 5.51 (Linux - x64)
; ExecutableFormat = Console
; CursorPosition = 64
; FirstLine = 15
; Folding = -
; EnableThread
; EnableXP
; Executable = qrun