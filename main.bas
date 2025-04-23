$Debug
$ExeIcon:'./qb64.ico'

Option _Explicit
' Make it like Lua
Option Base 1

' Type defs
' Floating text
Type Flotext
  alive As Integer
  text As String
  x As Single
  y As Single
  vy As Single
  ttl As Double ' in seconds
End Type

Type Particle
  alive As Integer
  img_handle As Integer
  x As Single
  y As Single
  vx As Single
  vy As Single
  gy As Single ' gravity
  ttl As Double ' in seconds
End Type

' Consts
Const TARGET_FPS = 60
Const WINDOW_WIDTH = 320
Const WINDOW_HEIGHT = 240
Const SCREEN_SCALE = 3

Const False = 0
Const True = Not False
Const PI = 3.1415926

' List keys in use
Const K_ESC = 27

Dim a

' Prepare the screen
' Ref: https://qb64.com/wiki/SCREEN
Dim buffer, scaled
buffer = _NewImage(WINDOW_WIDTH, WINDOW_HEIGHT, 32)
scaled = _NewImage(WINDOW_WIDTH * SCREEN_SCALE, WINDOW_HEIGHT * SCREEN_SCALE, 32)
Screen scaled: _Dest buffer: _Delay 0.1: _Display

' 32-bit colours should be used after changing the screen mode
Dim img_pyong, img_apple_tree, img_nugget, img_crafting_table, img_ethel
Dim img_icon_part, img_icon_usable_part
img_pyong = _LoadImage("images\pyong.png", 32)
img_apple_tree = _LoadImage("images\apple_tree.png", 32)
img_nugget = _LoadImage("images\nugget.png", 32)
img_crafting_table = _LoadImage("images\crafting_table.png", 32)

img_icon_part = _LoadImage("images\part.png", 32)
img_icon_usable_part = _LoadImage("images\usable_part.png", 32)
img_ethel = _LoadImage("images\ethel.png", 32)

Dim Shared bgm_doodle, bgm_construction
Dim Shared sfx_yippee, sfx_scream
bgm_doodle = _SndOpen("bgm\doodle.ogg")
bgm_construction = _SndOpen("bgm\construction.ogg")
sfx_yippee = _SndOpen("sfx\yippee.ogg")
sfx_scream = _SndOpen("sfx\cat_scream.ogg")

Dim As Long cornflower_blue, white
cornflower_blue = _RGB32(&H64, &H95, &HED) ' &hFF6495ED
white = _RGB32(&HFF, &HFF, &HFF)

Dim Shared As Flotext Flotexts(10)
Dim Shared img_particles(3)
For a = 1 To 3
  img_particles(a) = _LoadImage("images\particles_" + LTrim$(Str$(a)) + ".png")
Next
Dim Shared As Particle Particles(30)


_Title "Keyboard Smasher Jam - By Hevanafa (Apr 2025)"

' Used in measurements
Dim As String s
Dim w, h
Dim As Double dt, last_time
last_time = Timer


' Begin game state
Dim Shared is_game, is_win, is_started, is_over
Dim As Double last_press_time
Dim As String last_key
Dim last_shake
Dim Shared As Double start_press_time, best_time, shake_time
best_time = 99999

Dim Shared parts, scraps
Dim required_scraps
Dim crafting_x, crafting_y

crafting_x = Fix((WINDOW_WIDTH - _Width(img_crafting_table)) / 2)
crafting_y = WINDOW_HEIGHT - _Height(img_crafting_table) - 20

' Finalisation
Randomize Timer
' Print text with transparent bg
_PrintMode _KeepBackground
_Font 8

LoadBestTime

is_game = True
required_scraps = 10
_SndVol bgm_construction, 0.5
_SndVol bgm_doodle, 0.2
_SndLoop bgm_doodle


Do
  _Limit TARGET_FPS


  ' Update
  dt = Timer - last_time
  last_time = Timer
  last_key = InKey$

  If shake_time > 0 Then shake_time = shake_time - dt

  If last_shake <> (shake_time > 0) Then
    last_shake = (shake_time > 0)
    If last_shake Then
      _SndSetPos bgm_construction, Rnd * 5
      _SndPlay bgm_construction
    Else
      _SndPause bgm_construction
    End If
  End If

  If is_game Then
    If last_key <> "" Then
      If last_key = " " _orelse (Asc("a") <= Asc(last_key) _Andalso Asc(last_key) <= Asc("z")) _orelse _
         (asc("0") <= asc(last_key) _andalso asc(last_keY) <= asc("9")) Then
        ' pressed = pressed + 1
        parts = parts + 1
        last_press_time = Timer
        shake_time = 0.4
        AddFlotext "+1", Fix(crafting_x + Rnd * 64), crafting_y, -1
        AddParticle img_particles(1 + Fix(Rnd * 3)), crafting_x + 16, crafting_y, (Rnd - 0.5) * 6, -6, 0.3

        If Not is_started Then
          is_started = True
          start_press_time = Timer
        End If
      End If
    End If

    If parts >= 10 Then
      scraps = scraps + 1
      parts = parts - 10
    End If

    If scraps >= required_scraps Then
      _SndPlay sfx_yippee
      is_win = True
      is_game = False
      SaveBestTime
    End If

    If GetPlayTime >= 10 Then
      is_over = True
      is_game = False
      _SndVol sfx_scream, 0.5
      _SndPlay sfx_scream
    End If

    For a = 1 To UBound(Flotexts)
      If Flotexts(a).alive Then
        Flotexts(a).y = Flotexts(a).y + Flotexts(a).vy
        Flotexts(a).ttl = Flotexts(a).ttl - dt

        If Flotexts(a).ttl <= 0 Then Flotexts(a).alive = False
      End If
    Next

    For a = 1 To UBound(Particles)
      If Particles(a).alive Then
        Particles(a).x = Particles(a).x + Particles(a).vx
        Particles(a).y = Particles(a).y + Particles(a).vy
        Particles(a).vy = Particles(a).vy + Particles(a).gy
        Particles(a).ttl = Particles(a).ttl - dt

        If Particles(a).ttl <= 0 Then Particles(a).alive = False
      End If
    Next
  End If

  If is_win Then
    If last_key = "r" Then
      ResetGame
    End If
  End If


  ' Draw
  Cls , cornflower_blue&

  _PutImage , img_apple_tree

  Dim offset_x, offset_y
  If shake_time > 0 Then
    offset_x = (Rnd - 0.5) * 6
    offset_y = (Rnd - 0.5) * 6
  Else
    offset_x = 0
    offset_y = 0
  End If
  _PutImage (40 + offset_x, WINDOW_HEIGHT - _Height(img_pyong) + offset_y), img_pyong

  _PutImage (crafting_x, crafting_y), img_crafting_table
  _PutImage (WINDOW_WIDTH - _Width(img_nugget), WINDOW_HEIGHT - _Height(img_nugget)), img_nugget

  ' _PutImage ((WINDOW_WIDTH - _Width(qb64_logo)) \ 2, (WINDOW_HEIGHT - _Height(qb64_logo)) \ 2), qb64_logo

  If is_game Then
    _PutImage (216, 30), img_ethel

    s = "The cat is stuck on a tree!"
    'w = _PrintWidth(s)
    PrintCentre s, 60
    s = "Make a tool to rescue it!"
    PrintCentre s, 70
    ' _PrintString (Fix((WINDOW_WIDTH - w) / 2), 60), s

    Dim As Double time_diff
    Dim radius
    time_diff = Timer - last_press_time

    radius = (1 - _IIf(time_diff < 0.4, time_diff, 0.4) / 0.4) * 20
    If radius < 0 Then radius = 20

    radius = radius + 10
    Circle (WINDOW_WIDTH / 2, WINDOW_HEIGHT - 80), radius, &HFFFFFFFF, 0, 2 * PI, 1

    _PutImage (Fix(WINDOW_WIDTH - _Width(img_icon_usable_part) / 2), WINDOW_HEIGHT - 140), img_icon_usable_part
    If is_started Then
      PrintCentre Str$(scraps) + " /" + Str$(required_scraps), WINDOW_HEIGHT - 120
    End If


    ' Begin particles & stuff
    For a = 1 To UBound(Particles)
      If Particles(a).alive Then _PutImage (Particles(a).x, Particles(a).y), Particles(a).img_handle
    Next

    ' Crafting progress bar
    If is_started Then
      Dim As Single perc
      perc = parts / 10
      Line (crafting_x, crafting_y - 20)-(Fix(crafting_x + perc * 64), crafting_y - 10), &HFF20FF20, BF
      Line (crafting_x, crafting_y - 20)-(crafting_x + 64, crafting_y - 10), &HFFFFFFFF, B
      ' _PrintString (24, 30), "Parts:" + Str$(parts)
    End If

    For a = 1 To UBound(Flotexts)
      If Flotexts(a).alive Then _PrintString (Flotexts(a).x, Flotexts(a).y), Flotexts(a).text
    Next

    If is_started Then
      PrintCentre LTrim$(Str$(GetPlayTime)) + "s", 40
    End If

    If Not is_started Then
      PrintCentre "Best:" + Str$(best_time) + "s", 40
      PrintCentre "-- Spam keys to start --", WINDOW_HEIGHT / 2
    End If
  End If

  If is_win Then
    _PutImage (Fix((WINDOW_WIDTH - _Width(img_ethel)) / 2), WINDOW_HEIGHT - _Height(img_ethel) - 20), img_ethel
    _PrintString (24, 20), "You win!"
  End If

  ' Locate 16, 1
  ' Print "Esc - quit";

  _PutImage , buffer, scaled
  _Display
Loop Until _KeyDown(K_ESC)

_SndClose bgm_doodle

System


Sub PrintCentre (s As String, y As Integer)
  Dim w
  w = _PrintWidth(s)
  _PrintString ((WINDOW_WIDTH - w) / 2, y), s
End Sub


Sub ResetGame
  parts = 0
  scraps = 0
  is_game = True
  is_win = False
  is_started = False
  is_over = False
  start_press_time = 0
End Sub


Sub AddFlotext (text As String, x As Single, y As Single, vy As Single)
  Dim a
  For a = 1 To UBound(Flotexts)
    If Not Flotexts(a).alive Then
      Flotexts(a).alive = True
      Flotexts(a).text = text
      Flotexts(a).x = x
      Flotexts(a).y = y
      Flotexts(a).vy = vy
      Flotexts(a).ttl = 0.4
      Exit Sub
    End If
  Next
End Sub

Sub AddParticle (img_handle As Integer, x As Single, y As Single, vx As Single, vy As Single, gy As Single)
  Dim a
  For a = 1 To UBound(Particles)
    If Not Particles(a).alive Then
      Particles(a).alive = True
      Particles(a).img_handle = img_handle
      Particles(a).x = x
      Particles(a).y = y
      Particles(a).vx = vx
      Particles(a).vy = vy
      Particles(a).gy = gy
      Particles(a).ttl = 0.4
      Exit Sub
    End If
  Next
End Sub


Function GetPlayTime#
  GetPlayTime = _IIf(is_started, Fix((Timer - start_press_time) * 100) / 100, 0)
End Function


Sub LoadBestTime
  If Not _FileExists("score.txt") Then Exit Sub
  Open "score.txt" For Input As #1
  Input #1, best_time
  Close #1
End Sub


Sub SaveBestTime
  If best_time < GetPlayTime Then Exit Sub
  best_time = GetPlayTime

  Open "score.txt" For Output As #1
  Print #1, LTrim$(Str$(best_time))
  Close #1
End Sub

