from tkinter import *

# canvas
wdw = Tk()

# window subdivisions
topFrame = Frame(wdw)
topFrame.pack()
botFrame = Frame(wdw)
botFrame.pack(side=BOTTOM)

# button widgets
btn_1 = Button(topFrame, text="Button 1", fg='red')
btn_2 = Button(topFrame, text="Button 2", fg='green')
btn_3 = Button(topFrame, text="Button 3", fg='blue')
btn_4 = Button(botFrame, text="Button 4", fg='purple')

# button creation and position
btn_1.pack(side=LEFT)
btn_2.pack(side=LEFT)
btn_3.pack(side=LEFT)
btn_4.pack(side=BOTTOM)

# execution
wdw.mainloop()

