VARINT x 10
VARLIST list1 10, 20, 30
VARLIST list2 40, 50, 60
COMBINE list1 list2
GET y 2 list1
ADD x y
VARLIST list3 70, 80, 90
SET list3 1 list2
COPY list4 list2
GET list5 1 list4
SET 100 2 list5
HLT
