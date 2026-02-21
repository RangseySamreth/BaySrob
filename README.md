# Bay Srob – 3D Restaurant Simulation Game

## Project Overview

**Bay Srob** is a single-player 3D restaurant simulation game developed using **Godot Engine** for the Object-Oriented Programming course.

In this game, players manage a restaurant by cooking food, serving customers, earning money, and collecting stars to level up. As the player progresses, new features such as machine upgrades and a drive-through order system become available.

---

## Gameplay Features

- Cook and serve food to customers  
- Earn money for each successful order  
- Collect stars to level up  
- Shop system for buying and upgrading machines  
- Drive-through car order system  
- Player item holding system (food & drinks)  
- Audio system (background music & sound effects)  
- Save and load player progress  

---

## OOP Concepts Used

This project demonstrates the following Object-Oriented Programming principles:

### 🔹 Singleton Pattern
Global `GameManager` script used to store and manage shared game data.

### 🔹 Encapsulation
Game data (money, level, owned items) is controlled through functions rather than direct modification.

### 🔹 Abstraction
Complex game logic is hidden behind simple function calls like `buy_item()`.

### 🔹 Inheritance
Scripts extend built-in Godot classes such as:
- `CharacterBody3D`
- `PathFollow3D`

### 🔹 Polymorphism
Functions like `_ready()` behave differently depending on the script.

### 🔹 Composition
Player scene is built from multiple components:
- HandSlot  
- RightHandSlot  
- CollisionShape  

### 🔹 Observer Pattern (Signals)
UI automatically updates when game data changes using signals.

### 🔹 Defensive Programming
Safe node access using `get_node_or_null()` to prevent runtime crashes.

---

## Technologies Used

- **Godot Engine 4.x**
- **GDScript**
- **Blender** (3D modeling & animation)
- **Godot Control Nodes** (2D UI System)

---

## Game Objective

The goal of the game is to:

- Serve customers efficiently  
- Earn stars to level up  
- Unlock new machines and upgrades  
- Manage both in-store and drive-through orders  

As levels increase, gameplay becomes more challenging and dynamic.

---

## Team Members

- **Van Sotheany**
- **Samreth Rangsey**

Institute of Technology of Cambodia  
Object-Oriented Programming – OOPR019  
Academic Year 2025–2026  

---
