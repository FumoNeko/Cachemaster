local function centerWrite(text)
  local width, height = term.getSize()
  local x, y = term.getCursorPos()
  term.setCursorPos(math.ceil((width / 2) - (text:len() / 2)), y)
  term.write(text)
end

-- driver code --
term.setBackgroundColor(colors.blue)
term.clear()

-- header
term.setCursorPos(1,1)
term.write("ITEM")
centerWrite("STORAGE")
term.setCursorPos(44,1)
term.write("NUM")

-- data background
term.setCursorPos(1,2)
local w,h = term.getSize()
for i = 1, 7 do
  term.setBackgroundColor(colors.gray)
  print(string.rep(" ",w))
  term.setBackgroundColor(colors.green)
  print(string.rep(" ",w))
end
term.setBackgroundColor(colors.gray)
print(string.rep(" ",w))

-- text data
term.setCursorPos(1,2)
for i = 1, 7 do
  term.setBackgroundColor(colors.gray)
  print("data")
  term.setBackgroundColor(colors.green)
  print("data")
end
term.setBackgroundColor(colors.gray)
print("data")

-- footer --
-- page number
term.setCursorPos(1,18)
term.setTextColor(colors.black)
term.setBackgroundColor(colors.yellow)
centerWrite("Page 1")

-- page arrows and exit key
term.setCursorPos(20,18)
print("<")
term.setCursorPos(31, 18)
print(">")
term.setCursorPos(1, 18)
term.setTextColor(colors.white)
term.setBackgroundColor(colors.red)
print("EXIT")
term.setCursorPos(1,1)

-- button functionality
local event, button, x, y = os.pullEvent("mouse_click")
if  y == 18 then
  if x <=4 then
    -- exit button
    term.setBackgroundColor(colors.black)
    term.clear()
  elseif x == 20 then
    -- page down
  elseif x == 31 then
    -- page up
  end
end
