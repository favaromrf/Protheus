User Function pcomissao()
    Local aArea := FWGetArea()

    chkfile("ZZA")

    FWCallApp("prj-pcomissoes")
    FWRestArea(aArea)
Return
