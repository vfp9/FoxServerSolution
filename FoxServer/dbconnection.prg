#include "FoxServer.h"
* ================================================================================== *
* DataBase connection simple class
* ================================================================================== *
Define Class DBConnection as Session
	Hidden cConStr, nHandle, cLastErrorMessage
	oUtility = .null.
	nHandle = 0
	cLastErrorMessage = ""

	Function OpenConnection
		If Empty(This.cConStr)
			This.oUtility.Log(LOG_ERROR, "No connection string defined for the database.")
			this.cLastErrorMessage = "No connection string defined for the database."
			Return .F.
		Endif

		If This.nHandle > 0
			&& TODO(irwin): realizar un ping para ver si responde.
*!*				this.PingServer()
			Return .T.
		EndIf

		This.nHandle = Sqlstringconnect(This.cConStr)
		If This.nHandle < 0
			Aerror(laSqlError)
			This.oUtility.Log(LOG_ERROR, "Error in OpenConnection: " + laSqlError[2])
			this.cLastErrorMessage = Transform(laSqlError[1]) + ':' + Transform(laSqlError[2])
			Return .F.
		Endif
		Return .T.
	Endfunc

	Procedure CloseConnection
		If This.nHandle > 0
			This.nHandle = 0
			SQLDisconnect(This.nHandle)
		Endif
	Endproc

	Function QueryToJson(tcQuery)
		Local lcResult As Memo, lcCursor
		lcResult = 'null'
		
		If !this.oUtility.LoadJsonFox()
			This.oUtility.Log(LOG_ERROR, "Error in QueryToJson: Could not load JSONFox library.")
			Return lcResult
		EndIf
		
		Try
			If This.nHandle > 0
				lcCursor = Sys(2015)
				If SQLExec(This.nHandle, tcQuery, lcCursor) < 0
					Aerror(laSqlError)
					This.oUtility.Log(LOG_ERROR, "Error in QueryToJson: " + laSqlError[2])
					this.cLastErrorMessage = Transform(laSqlError[1]) + ':' + Transform(laSqlError[2])
				Else
					If Reccount(lcCursor) > 0
						lcResult = This.oUtility.oJson.cursorToJson(lcCursor, .F., This.DataSessionId, .T., .T., .T.)
					Endif
				Endif
			Endif
		Catch To loEx
			Local lcMsg
			lcMsg = This.oUtility.GetExceptionMessage(loEx)
			This.oUtility.Log(LOG_ERROR, lcMsg)
		Endtry
		Return lcResult
	Endfunc

	Function ExecuteNonQuery(tcQuery)
		Local lbResult As Boolean
		lbResult = .T.
		
		Try
			If This.nHandle > 0
				If SQLExec(This.nHandle, tcQuery) < 0
					lbResult = .F.
					Aerror(laSqlError)
					This.oUtility.Log(LOG_ERROR, "Error in ExecuteNonQuery: " + laSqlError[2])
					this.cLastErrorMessage = Transform(laSqlError[1]) + ':' + Transform(laSqlError[2])
				Endif
			Endif
		Catch To loEx
			Local lcMsg
			lcMsg = This.oUtility.GetExceptionMessage(loEx)
			This.oUtility.Log(LOG_ERROR, lcMsg)
			lbResult = .F.
		Endtry
		Return lbResult
	Endfunc
	
	Function ExecuteQuery(tcQuery, tcCursor)
		Local lvResult As Variant, lbReturnObject
		lvResult = .T.
		If Empty(tcCursor)
			lbReturnObject = .T.
			tcCursor = Sys(2015)
			lvResult = CreateObject("Collection")
		EndIf
		Try
			If This.nHandle > 0
				If SQLExec(This.nHandle, tcQuery, tcCursor) < 0
					If !lbReturnObject
						lvResult = .F.
					EndIf
					Aerror(laSqlError)
					This.oUtility.Log(LOG_ERROR, "Error in ExecuteQuery: " + laSqlError[2])
					this.cLastErrorMessage = Transform(laSqlError[1]) + ':' + Transform(laSqlError[2])
				EndIf
				If lbReturnObject
					If Used(tcCursor) and Reccount(tcCursor) > 0
						Select (tcCursor)
						Scan
							Scatter memo name loRow
							lvResult.Add(loRow)
						EndScan
					EndIf
				EndIf
			Else
				If !lbReturnObject
					lvResult = .F.
				EndIf
			EndIf
		Catch To loEx
			Local lcMsg
			lcMsg = This.oUtility.GetExceptionMessage(loEx)
			This.oUtility.Log(LOG_ERROR, lcMsg)
			If !lbReturnObject
				lvResult = .F.
			EndIf
		Endtry
		Return lvResult
	Endfunc

	Function GetHandle
		Return this.nHandle
	EndFunc
	
	Procedure SetConnectionString(tcConStr)
		this.cConStr = tcConStr
	EndProc
	
	Function GetLastError as string
		Return this.cLastErrorMessage
	EndFunc
	
	Function GetLastID(tcCustomQuery) as object		
		If Empty(tcCustomQuery)
			tcCustomQuery = "select LAST_INSERT_ID() as id;" && solo para MySQL/MariaDB
		EndIf
		&& 12/10/2023 TODO(irwin): usar una clase abstracta para los distintos motores.
		Return This.ExecuteQuery(tcCustomQuery)
	EndFunc
	
EndDefine
