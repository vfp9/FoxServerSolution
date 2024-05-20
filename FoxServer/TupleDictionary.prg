* ================================================================================== *
* TupleDictionary Class (uses a Tuple as entry)
* ================================================================================== *
define class TupleDictionary as collection olepublic

	function Exists(tcKey) as Boolean
		Local loEntry
		For each loEntry in this
			If loEntry.GetKey() == tcKey
				Return .t.
			EndIf
		EndFor
		Return .f.
	endfunc

	function AddEntry(toEntry as Tuple) as VOID
		Local lcKey
		lcKey = toEntry.GetKey()
		if this.Exists(lcKey)
			this.remove(this.getkey(lcKey))
		endif
		this.add(toEntry.GetValue(), toEntry.GetKey())
	EndFunc
	
	Function GetIndex(tcKey) as Boolean
		Local loEntry, i
		For i=1 to this.Count
			loEntry = this.Item(i)
			If loEntry.GetKey() == tcKey
				Return i
			EndIf
		EndFor
		Return 0
	EndFunc

	function Get(tvIndexOrKey) as Variant
		do case
		case type('tvIndexOrKey') == 'N'
			if !between(tvIndexOrKey, 1, this.count)
				return .null.
			endif
			return this.item(tvIndexOrKey)
		case type('tvIndexOrKey') == 'C'
			tvIndexOrKey = this.getIndex(tvIndexOrKey)
			if tvIndexOrKey > 0
				return this.item(tvIndexOrKey)
			endif
		endcase
		return .null.
	EndFunc
	
	function GetValue(tvIndexOrKey) as Variant
		Local loEntry
		loEntry = this.Get(tvIndexOrKey)
		return Iif(!IsNull(loEntry), loEntry.GetValue(), loEntry)
	endfunc
EndDefine
