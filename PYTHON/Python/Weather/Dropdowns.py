from tkinter import *
import glob
import os


def dic_imgs():
    imgs = {}
    for f in glob.glob("/usr/share/icons/Pop/64x64/apps/*.png"):
        fname = f
        f = os.path.basename(f)
        name = f.split(".")[0]
        imgs[name] = PhotoImage(file=fname)
    return imgs


def commandStub():
    print("Command Stub")


rootWin = Tk()
rootWin.title("GUI Tests")
rootWin.geometry("500x500")
imgs = dic_imgs()

# Create Main Menu
topMenu = Menu(rootWin)
rootWin.config(menu=topMenu)

fileSub = Menu(topMenu)
topMenu.add_cascade(label="File", menu=fileSub)

fileSub.add_command(label="Open", command=commandStub)
fileSub.add_command(label="Close", command=commandStub)
fileSub.add_command(label="Recent", command=commandStub)
fileSub.add_separator()
fileSub.add_command(label="Exit", command=commandStub)

editSub = Menu(topMenu)
topMenu.add_cascade(label="Edit", menu=editSub)
editSub.add_command(label="Undo", command=commandStub)
editSub.add_command(label="Redo", command=commandStub)

# Create Toolbar Menu
toolBar = Frame(rootWin)
toolBar.pack(side=TOP, fill=X)

tbBtn1 = Button(
    toolBar,
    relief=FLAT,
    compound=TOP,
    text="Calc",
    command=commandStub,
    image=imgs["calc"])
tbBtn1.pack(side=LEFT, padx=0, pady=0)

tbBtn2 = Button(
    toolBar,
    relief=FLAT,
    compound=TOP,
    text="Gedit",
    command=commandStub,
    image=imgs["gedit"])
tbBtn2.pack(side=LEFT, padx=0, pady=0)

# Create Status Bar
statusBar = Label(rootWin, text="Current status is critical", bd=1, relief=SUNKEN, anchor=W)
statusBar.pack(side=BOTTOM, fill=X)

rootWin.mainloop()
