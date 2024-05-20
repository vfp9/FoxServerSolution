#include "FoxServer.h"
Define Class Logger as Custom
	Hidden cLogFile

	Procedure SetLogFile(tcLogFile)
		this.cLogFile = tcLogFile
	EndProc	

	procedure Log(tnType, tcMessage)
		If Empty(This.cLogFile)
			This.cLogFile = FullPath('FoxServer.log')
		Endif
		If Type('tnType') == 'C'
			tcMessage = tnType
			tnType = LOG_INFO
		EndIf
		Try
			Local lcLogText As Memo, lcDateAct As String, lcCenturyAct As String, lcType, lnHour

			lcDateAct 	 = Set("Date")
			lcCenturyAct = Set("Century")
			lcType 		 = ""
			lnHour		 = Set("Hours")
			
			Set Date Italian
			Set Century On
			Set Hours To 24
			
			Do Case
			Case tnType = LOG_ERROR
				lcType = "ERROR  "
			Case tnType = LOG_INFO
				lcType = "INFO   "
			Case tnType = LOG_WARNING
				lcType = "WARNING"
			Endcase

			lcLogText = Textmerge("<<Ttoc(Datetime())>> | <<lcType>> | <<tcMessage>>") + CRLF
			=Strtofile(lcLogText, This.cLogFile, 1)
		Catch
		Finally
			Set Century &lcCenturyAct
			Set Date &lcDateAct
			Set Hours To (lnHour)
		Endtry
	endproc
EndDefine