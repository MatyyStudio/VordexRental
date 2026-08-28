# 🚗 Vordex Rental | Advanced Vehicle Rental System

![FiveM](https://img.shields.io/badge/FiveM-Ready-orange.svg)
![Optimization](https://img.shields.io/badge/Optimization-0.00ms-green.svg)
![Framework](https://img.shields.io/badge/Framework-ESX%20%7C%20QBCore-blue.svg)

A modern, highly optimized, and feature-rich vehicle rental script for FiveM. Built specifically to eliminate abandoned rental cars across the server while providing a highly interactive and clean user experience using `ox_lib` and `ox_target`.

## ✨ Features

* **0.00ms Performance:** No slow `Wait(0)` loops or 3D text markers. Everything is strictly target-based and event-driven.
* **Modern UI:** Utilizes `ox_lib` context menus, input dialogs, and text UI for a seamless look.
* **Smart Time Management:** 
  * Players rent vehicles for a specific amount of time (minutes).
  * A real-time UI timer tracks the remaining time.
  * **Expiration Logic:** If time expires and the player is *inside* the vehicle, the engine shuts off and they are prompted to pay a penalty to extend the time, or leave the vehicle. If they are *outside*, the vehicle is automatically deleted to keep the map clean.
* **Deposit & Damage System:** 
  * Players pay a deposit upfront.
  * Upon returning the vehicle, the script checks the engine and body health. Damages result in a calculated deduction from the returned deposit.
* **Early Return Refunds:** If a player returns a vehicle before their time expires, they receive a partial refund for the unused time (configurable).
* **Personal Tracker:** The rented vehicle gets a client-side map blip, meaning only the player who rented it can see its location on the map.
* **Payment Options:** Players can choose to pay with Cash or Bank.
* **Multi-Framework:** Automatically detects and bridges with **ESX** and **QBCore** for economy management.

## 📦 Dependencies

Ensure you have the following resources installed and running on your server before starting this script:
* [ox_lib](https://github.com/overextended/ox_lib)
* [ox_target](https://github.com/overextended/ox_target)
* **ESX** or **QBCore** (For economy. Can be modified for standalone).

## 🚀 Installation

1. Download the latest release from the repository.
2. Extract the folder and ensure it is named `VordexRental`.
3. Place the `VordexRental` folder into your server's `resources` directory.
4. Add the following line to your `server.cfg`:

```cfg
ensure ox_lib
ensure ox_target
ensure VordexRental