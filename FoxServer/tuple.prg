Define Class Tuple As Custom OlePublic
	Hidden cKey, vValue

	Procedure SetKey(tcKey as string) as VOID
		If Type('tcKey') != 'C'
			Return
		EndIf
		this.cKey = tcKey
	EndProc
	
	Function GetKey as String
		Return this.cKey
	EndFunc
	
	Procedure SetValue(tvValue as Variant) as VOID
		this.vValue = tvValue
	EndProc
	
	Function GetValue as Variant
		Return this.vValue
	EndFunc
	
Enddefine
