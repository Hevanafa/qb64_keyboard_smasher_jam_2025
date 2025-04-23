$Debug
$ExeIcon:'./qb64pe.ico'
$Color:0

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
  colour As Integer
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
Const K_F2 = 15360

Dim a

' Prepare the screen
' Ref: https://qb64.com/wiki/SCREEN
Dim Shared buffer, scaled
buffer = _NewImage(WINDOW_WIDTH, WINDOW_HEIGHT, 32)
scaled = _NewImage(WINDOW_WIDTH * SCREEN_SCALE, WINDOW_HEIGHT * SCREEN_SCALE, 32)
Screen scaled: _Dest buffer: _Delay 0.1: _Display

' 32-bit colours should be used after changing the screen mode
Dim img_pyong, img_apple_tree, img_nugget, img_crafting_table, img_ethel, img_ladder
Dim img_icon_part, img_icon_usable_part
img_pyong = _LoadImage("images\pyong.png", 32)
img_apple_tree = _LoadImage("images\apple_tree_new.png", 32)
img_nugget = _LoadImage("images\nugget.png", 32)
img_crafting_table = _LoadImage("images\crafting_table.png", 32)
img_ladder = _LoadImage("images\ladder.png", 32)

img_icon_part = _LoadImage("images\part.png", 32)
img_icon_usable_part = _LoadImage("images\usable_part.png", 32)
img_ethel = _LoadImage("images\ethel.png", 32)

Dim Shared bgm_doodle, bgm_construction
Dim Shared sfx_yippee, sfx_scream
bgm_doodle = _SndOpen("bgm\doodle.ogg")
bgm_construction = _SndOpen("bgm\construction.ogg")
sfx_yippee = _SndOpen("sfx\yippee.ogg")
sfx_scream = _SndOpen("sfx\cat_scream.ogg")

Dim As Long cornflower_blue
cornflower_blue = _RGB32(&H64, &H95, &HED) ' &hFF6495ED
' white = _RGB32(&HFF, &HFF, &HFF)

Dim Shared As Flotext Flotexts(10)

Dim ladder_blink_time
Dim Shared img_particles(3)
For a = 1 To 3
  img_particles(a) = _LoadImage("images\particles_" + LTrim$(Str$(a)) + ".png")
Next
Dim Shared As Particle Particles(30)

Dim Shared img_clouds(3)
Dim cloud_sprite_idx: cloud_sprite_idx = 1
Dim As Double cloud_elapsed_time
For a = 1 To 3
  img_clouds(a) = _LoadImage("images\clouds_" + LTrim$(Str$(a)) + ".png")
Next


_Title "Keyboard Smasher Jam - By Hevanafa (Apr 2025)"
_ScreenMove _Middle

' Used in measurements
Dim As String s
Dim w, h
Dim As Double dt, last_time
last_time = Timer


' Begin game state
Dim Shared is_game, is_win, is_started, is_lose, is_new_best
Dim Shared last_f2
Dim As Double last_press_time
Dim As String last_key
Dim last_shake
Dim Shared As Double start_press_time, best_time, shake_time, finish_time
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

  If last_f2 <> _KeyDown(K_F2) Then
    last_f2 = _KeyDown(K_F2)
    If last_f2 Then PerformScreenshot
  End If

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
      'If last_key = " " _orelse (Asc("a") <= Asc(last_key) _Andalso Asc(last_key) <= Asc("z")) _orelse _
      '   (asc("0") <= asc(last_key) _andalso asc(last_keY) <= asc("9")) Then

      If 32 <= Asc(last_key) _Andalso Asc(last_key) <= 126 Then
        ' pressed = pressed + 1
        parts = parts + 1
        last_press_time = Timer
        shake_time = 0.4

        Dim idx: idx = FindUnusedFlotext
        AddFlotext "+1", Fix(crafting_x + Rnd * 64), crafting_y, -1
        If idx > 0 Then FlotextColour Flotexts(idx), hsv2rgb(Rnd, 1, 1)

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
      finish_time = GetPlayTime
      is_new_best = (best_time > finish_time)

      SaveBestTime
    End If

    If shake_time > 0 Then
      cloud_elapsed_time = cloud_elapsed_time + dt

      If cloud_elapsed_time > 0.33 Then
        cloud_elapsed_time = 0
        cloud_sprite_idx = cloud_sprite_idx + 1

        If cloud_sprite_idx > 3 Then cloud_sprite_idx = 1
      End If
    End If

    ladder_blink_time = ladder_blink_time + dt

    If GetPlayTime >= 10 Then
      is_lose = True
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
    If last_key = "r" Then ResetGame
  End If

  If is_lose Then
    If last_key = "r" Then ResetGame
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
  _PutImage (50 + offset_x, WINDOW_HEIGHT - _Height(img_pyong) + offset_y), img_pyong

  _PutImage (crafting_x, crafting_y), img_crafting_table
  _PutImage (WINDOW_WIDTH - _Width(img_nugget), WINDOW_HEIGHT - _Height(img_nugget)), img_nugget

  ' _PutImage ((WINDOW_WIDTH - _Width(qb64_logo)) \ 2, (WINDOW_HEIGHT - _Height(qb64_logo)) \ 2), qb64_logo

  If is_game Then
    _PutImage (216, 30), img_ethel

    s = "The cat is stuck on a tree!"
    'w = _PrintWidth(s)
    ' PrintCentre s, 60
    PrintCentreOutline s, 60
    s = "Make a tool to rescue it!"
    PrintCentreOutline s, 70
    ' _PrintString (Fix((WINDOW_WIDTH - w) / 2), 60), s

    Dim As Double time_diff
    Dim radius
    time_diff = Timer - last_press_time

    radius = (1 - _IIf(time_diff < 0.4, time_diff, 0.4) / 0.4) * 20
    If radius < 0 Then radius = 20

    radius = radius + 10
    Circle (WINDOW_WIDTH / 2, WINDOW_HEIGHT - 80), radius, &HFFFFFFFF, 0, 2 * PI, 1

    ' Floating ladder
    If is_started Then
      Dim As Single t
      Dim As Integer go_down
      t = FMod(Timer, 1)
      go_down = t > 0.5
      offset_y = _IIf(go_down = True, LerpInOutQuad(-10, 10, t), LerpInOutQuad(10, -10, t))
      Dim img: img = _IIf((Fix(ladder_blink_time) And 1) > 0, img_icon_usable_part, img_ladder)
      _PutImage (Fix(WINDOW_WIDTH - _Width(img_icon_usable_part)) / 2, WINDOW_HEIGHT - 140 + offset_y), img
      PrintCentreOutline Str$(scraps) + " /" + Str$(required_scraps), WINDOW_HEIGHT - 120
    End If


    ' Begin particles & stuff
    If shake_time > 0 Then
      _PutImage (crafting_x, crafting_y - 20), img_clouds(cloud_sprite_idx)
    End If

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
      If Flotexts(a).alive Then
        Color Flotexts(a).colour
        _PrintString (Flotexts(a).x, Flotexts(a).y), Flotexts(a).text
      End If
    Next
    Color &HFFFFFFFF


    If is_started Then
      PrintCentreOutline LTrim$(Str$(GetPlayTime)) + "s", 40
    End If

    If Not is_started Then
      PrintCentreOutline "Best:" + Str$(best_time) + "s", 40
      PrintCentreOutline "-- Spam keys to start --", WINDOW_HEIGHT / 2
    End If
  End If

  If is_win Then
    _PutImage (Fix((WINDOW_WIDTH - _Width(img_ethel)) / 2), WINDOW_HEIGHT - _Height(img_ethel) - 20), img_ethel

    PrintCentreOutline "You win!", 20

    PrintCentreOutline LTrim$(Str$(finish_time)) + "s", 40
    If is_new_best Then
      PrintCentreOutline "(New best)", 50
    End If
    PrintOutline "R - restart", 10, WINDOW_HEIGHT - 20
  End If

  If is_lose Then
    PrintOutline "Time's up!", 24, 20
    PrintOutline "R - restart", 10, WINDOW_HEIGHT - 20
  End If

  ' Locate 16, 1
  ' Print "Esc - quit";

  _PutImage , buffer, scaled
  _Display
Loop Until _KeyDown(K_ESC)

_SndClose bgm_doodle
_SndClose bgm_construction

System


Sub PrintCentre (s As String, y As Integer)
  Dim w: w = _PrintWidth(s)
  _PrintString ((WINDOW_WIDTH - w) / 2, y), s
End Sub

' fg As Long, outline As Long
Sub PrintCentreOutline (s As String, y As Integer)
  Dim x
  Dim w: w = _PrintWidth(s)
  x = Fix((WINDOW_WIDTH - w) / 2)
  PrintOutline s, x, y
End Sub

Sub PrintOutline (s As String, x As Integer, y As Integer)
  Dim As Long last_colour: last_colour = _DefaultColor

  ' Color outline
  Color &HFF000000
  _PrintString (x - 1, y), s
  _PrintString (x + 1, y), s
  _PrintString (x, y - 1), s
  _PrintString (x, y + 1), s

  ' Color fg
  Color &HFFFFFFFF
  _PrintString (x, y), s

  Color last_colour
End Sub


Sub ResetGame
  parts = 0
  scraps = 0
  is_game = True
  is_win = False
  is_started = False
  is_lose = False
  is_new_best = False
  start_press_time = 0
End Sub


Sub AddFlotext (text As String, x As Single, y As Single, vy As Single)
  Dim a: a = FindUnusedFlotext
  If a < 0 Then Exit Sub
  Flotexts(a).alive = True
  Flotexts(a).text = text
  Flotexts(a).x = x
  Flotexts(a).y = y
  Flotexts(a).vy = vy
  Flotexts(a).ttl = 0.4
  Flotexts(a).colour = &HFFFFFFFF
End Sub

Function FindUnusedFlotext%
  Dim a
  FindUnusedFlotext = -1
  For a = 1 To UBound(Flotexts)
    If Not Flotexts(a).alive Then
      FindUnusedFlotext = a
      Exit Function
    End If
  Next
End Function

Sub FlotextColour (ref As Flotext, colour As Integer)
  ref.colour = colour
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
  GetPlayTime = _IIf(is_started, CInt((Timer - start_press_time) * 100) / 100, 0)
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


' https://stackoverflow.com/questions/17242144
' { 0 <= h, s, v <= 1 }
Function hsv2rgb& (h As Double, s As Double, v As Double)
  Dim As Double r, g, b, i, f, p, q, t

  i = Fix(h * 6)
  f = h * 6 - i
  p = v * (1 - s)
  q = v * (1 - f * s)
  t = v * (1 - (1 - f) * s)

  Select Case i Mod 6
    Case 0
      r = v: g = t: b = p
    Case 1
      r = q: g = v: b = p
    Case 2
      r = p: g = v: b = t
    Case 3
      r = p: g = q: b = v
    Case 4
      r = t: g = p: b = v
    Case 5
      r = v: g = p: b = q
  End Select

  ' hsv2rgb = &HFF000000 + Fix(r * 65536) + Fix(g * 256) + Fix(b)
  hsv2rgb = _RGB32(r * 255, g * 255, b * 255, 255)
End Function

Function Lerp# (a#, z#, perc#)
  Lerp = (z# - a#) * Clamp(perc#, 0, 1) + a#
End Function

Function Clamp# (value#, a#, z#)
  Clamp = _IIf(value# < a#, a#, _IIf(value# > z#, z#, value#))
End Function


Function EaseInOutQuad# (x As Double)
  EaseInOutQuad = _IIf(x < 0.5, 2 * x ^ 2, 1 - (-2 * x + 2) ^ 2 / 2)
End Function

Function LerpInOutQuad# (a As Double, z As Double, perc As Double)
  LerpInOutQuad = Lerp(a, z, EaseInOutQuad(perc))
End Function

Function FMod# (n As Double, div As Double)
  FMod = n - Fix(n / div) * div
End Function

Sub PerformScreenshot
  Dim dump$
  $If WEB Then
    Print "Not supported!";
    Flush
    Input "", dump$
  $Else
    If Not _DirExists("screenshots") Then
      MkDir "screenshots"
    End If

    Dim filename$
    filename$ = "screenshots\" + LTrim$(Str$(CLng(Timer))) + ".png"

    _SaveImage filename$, scaled

    Locate 2, 1
    Print "Saved as " + filename$;
    Locate 3, 1
    Print "Press Enter"

    ' Flush
    _PutImage , buffer, scaled
    _Display

    Input "", dump$
  $End If
End Sub


Sub StartWinSequence
End Sub
