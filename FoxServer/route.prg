Define Class Route As Custom OlePublic
	Hidden cMethod, cPath, cFuncName

	Procedure SetMethod(tcMethod as String) as VOID
		If Type('tcMethod') != 'C'
			tcMethod = Space(1)
		EndIf
		this.cMethod = tcMethod
	EndProc
	
	Function GetMethod as String
		Return this.cMethod
	EndFunc
	
	Procedure SetPath(tcPath as String) as VOID
		If Type('tcPath') != 'C'
			tcPath = Space(1)
		EndIf
		this.cPath = tcPath
	EndProc
	
	Function GetPath as String
		Return this.cPath
	EndFunc

	Procedure SetFuncName(tcFuncName as String) as VOID
		If Type('tcMethod') != 'C'
			tcFuncName = Space(1)
		EndIf
		this.cFuncName = tcFuncName
	EndProc
	
	Function GetFuncName as String
		Return this.cFuncName
	EndFunc
	
Enddefine
