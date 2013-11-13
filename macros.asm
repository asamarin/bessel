; Fichero de definicion de macros 

; Macro para obtener el estado de la FPU y realizar comparaciones
FPU_STATUS macro
    push ax
    fstsw ax
    sahf
    pop ax
endm   

; Macro para calcular la delta que hay que sumar a "x" en cada paso
Calc_step_amnt macro hWnd
    finit
    fild upper_lim
    fild lower_lim
    fsub
    fild n_values
    fdiv 
    fstp step_amnt
endm

; Macro para enviar ciertos mensajes a los controles graficos y ajustar propiedades
Set_controls_properties macro
    invoke CreateCol, hDlg, 0, LVCFMT_LEFT, offset Column1_Caption, 40    
    invoke CreateCol, hDlg, 1, LVCFMT_CENTER, offset Column2_Caption, 70
    invoke CreateCol, hDlg, 2, LVCFMT_CENTER, offset Column3_Caption, NULL
    invoke SendDlgItemMessage, hDlg, IDC_LISTVIEW, LVM_SETEXTENDEDLISTVIEWSTYLE, LVS_EX_GRIDLINES, LVS_EX_GRIDLINES
    invoke SendDlgItemMessage, hDlg, IDC_LISTVIEW, LVM_SETEXTENDEDLISTVIEWSTYLE, LVS_EX_FULLROWSELECT, LVS_EX_FULLROWSELECT
    invoke SendDlgItemMessage, hDlg, IDC_SPIN1, UDM_SETRANGE32, SPINBOX_LLIMIT, SPINBOX_ULIMIT
    invoke SendDlgItemMessage, hDlg, IDC_SPIN2, UDM_SETRANGE32, SPINBOX_LLIMIT, SPINBOX_ULIMIT
    invoke SendDlgItemMessage, hDlg, IDC_NUMVAL, EM_SETLIMITTEXT, 5, NULL
    invoke SendDlgItemMessage, hDlg, IDC_PROGRESS, PBM_SETSTEP, 1, NULL
    invoke UpdateWindow, hDlg 
    invoke GetDlgItem, hDlg, IDC_LISTVIEW
    invoke SetFocus, eax
endm