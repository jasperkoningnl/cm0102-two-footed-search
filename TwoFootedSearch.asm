
push ebp
mov ebp, esp
push ebx
push esi
push edi
push dword ptr [ebp+20]
push dword ptr [ebp+16]
push dword ptr [ebp+12]
push dword ptr [ebp+8]
call 0x53ee50
add esp, 16
pushfd
pushad
mov esi, dword ptr [ebp+8]
test esi, esi
jz finished
cmp byte ptr [esi+0x30], 15
jl finished
cmp byte ptr [esi+0x3b], 14
jl finished
mov edi, dword ptr [ebp+12]
test edi, edi
jz finished
mov ecx, dword ptr [ebp+16]
cmp ecx, 5
jl finished
find_end:
cmp byte ptr [edi], 0
je found_end
inc edi
dec ecx
cmp ecx, 5
jge find_end
jmp finished
found_end:
mov dword ptr [edi], 0x292b2820
mov byte ptr [edi+4], 0
finished:
popad
popfd
pop edi
pop esi
pop ebx
pop ebp
ret
