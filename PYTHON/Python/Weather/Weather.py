from tkinter import *
import os
import sys
import requests

HEIGHT = 700
WIDTH = 800
API_KEY = "63525f41519d5209cc2b0e0ff54b65b1"


def format_response(weather):
    try:
        name = weather['name']
        desc = weather['weather'][0]['description']
        temp = weather['main']['temp']

        final_str = 'City: %s \nConditions: %s \nTemperature (°F): %s' % (name, desc, temp)
    except:
        final_str = 'There was a problem retrieving the information'

    return final_str


def get_weather(city):
    url = "https://api.openweathermap.org/data/2.5/weather"
    params = {'APPID': API_KEY, 'q': city, 'units': 'imperial'}
    response = requests.get(url, params=params)
    weather = response.json()

    label['text'] = format_response(weather)


def get_path(fn):
    if hasattr(sys, "_MEIPASS"):
        return f'{os.path.join(sys._MEIPASS, fn)}'
    else:
        return f'{fn}'


root = Tk()
root.title("Weather")

canvas = Canvas(root, height=HEIGHT, width=WIDTH)
canvas.pack()
background_image = PhotoImage(file=get_path("landscape.png"))
background_label = Label(root, image=background_image)
background_label.place(x=0, y=0, relwidth=1, relheight=1)

frame = Frame(root, bg='#80c1ff', bd=5)
frame.place(relx=0.5, rely=0.1, relwidth=0.75, relheight=0.1, anchor='n')

city_input = Entry(frame, font=40)
city_input.bind("<Return>", (lambda event: get_weather(city_input.get())))
city_input.place(relwidth=0.65, relheight=1)
city_input.focus_set()

button = Button(frame, text="Get Weather", font=40, command=lambda: get_weather(city_input.get()))
button.place(relx=0.7, relheight=1, relwidth=0.3)

lower_frame = Frame(root, bg='#80c1ff', bd=10)
lower_frame.place(relx=0.5, rely=0.25, relwidth=0.75, relheight=0.6, anchor='n')

label = Label(lower_frame, font=('Liberation Sans', 16), anchor='nw', justify='left', bd=4)
label.place(relheight=1, relwidth=1)

root.mainloop()
