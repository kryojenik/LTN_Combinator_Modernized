#!/usr/bin/env python3

import json
import os
from zipfile import ZipFile

modFiles = [
	"info.json",
	"changelog.txt",
	"thumbnail.png",
	"config.lua",
	"control.lua",
	"data-final-fixes.lua",
	"data.lua",
	"settings.lua",
]
modFolders = [
	"graphics",
	"locale",
	"migrations",
	"prototypes",
	"script",
]

with open("info.json") as file:
	modInfo = json.load(file)

zipName = "{}_{}".format(modInfo["name"], modInfo["version"])

with ZipFile("{}.zip".format(zipName), 'w') as modZip:
	for file in modFiles:
		modZip.write(file, arcname="{}/{}".format(zipName, file))
	for folder in modFolders:
		for root, dirs, files in os.walk(folder):
			for file in files:
				filePath = os.path.join(root, file)
				archivePath = os.path.relpath(filePath, os.path.join(folder, '..'))
				modZip.write(filePath, arcname="{}/{}".format(zipName, archivePath))
