from tkinter import *

# canvas
wdw = Tk()

# window subdivisions
topFrame = Frame(wdw)
topFrame.grid(row=0)
botFrame = Frame(wdw)
botFrame.grid(row=4)

# button widgets
btn_1 = Button(topFrame, text="Button 1", fg='red')
btn_2 = Button(topFrame, text="Button 2", fg='green')
btn_3 = Button(topFrame, text="Button 3", fg='blue')
btn_4 = Button(botFrame, text="Button 4", fg='purple')

# label widgets
lbl_1 = Label(text='Name')
lbl_2 = Label(text='Password')

# checkbox widgets
chk_1 = Checkbutton(wdw, text="keep me logged in")

# entry widgets (like input boxes)
ent_1 = Entry(wdw)
ent_2 = Entry(wdw)

# widget creation and position
btn_1.grid(row=0, column=0)
btn_2.grid(row=0, column=1)
btn_3.grid(row=0, column=2)
btn_4.grid(row=0, column=0)

# label widgets sticky (justification) uses compass coords N,E,S,W)
lbl_1.grid(row=1, column=0, sticky=E)
ent_1.grid(row=1, column=1)

lbl_2.grid(row=2, column=0, sticky=E)
ent_2.grid(row=2, column=1)

chk_1.grid(row=3, columnspan=2)

# execution
wdw.mainloop()

