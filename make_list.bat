@echo off
if "%1"=="" (
	echo Error: DEST is empty
	exit /b 1
)
set SRC=%cd%
cd %1
set DEST=%cd%
if "%SRC%"=="%DEST%" (
	echo Error: SRC==DEST
	exit /b 1
)

cd %DEST%
rmdir /s /q crossbeats
mkdir crossbeats
cd crossbeats

mkdir comrank
mklink comrank\app.rb %SRC%\comrank\app.rb
mklink /d comrank\lib %SRC%\comrank\lib
mklink /d comrank\views %SRC%\comrank\views
mklink /d comrank\stylesheets %SRC%\comrank\stylesheets
mklink /d comrank\javascripts %SRC%\comrank\javascripts

mkdir cxbrank
mklink cxbrank\rackup.bat %SRC%\cxbrank\rackup.bat
mklink cxbrank\rake.bat %SRC%\cxbrank\rake.bat
mklink cxbrank\config.ru %SRC%\cxbrank\config.ru
mklink cxbrank\index.rb %SRC%\cxbrank\index.rb
mklink cxbrank\app.rb %SRC%\cxbrank\app.rb
mklink cxbrank\Gemfile %SRC%\cxbrank\Gemfile
mklink cxbrank\Gemfile.lock %SRC%\cxbrank\Gemfile.lock
mklink cxbrank\Rakefile %SRC%\cxbrank\Rakefile
mkdir cxbrank\config
copy %SRC%\cxbrank\config\config.yml cxbrank\config
copy %SRC%\cxbrank\config\database.yml cxbrank\config
mklink /d cxbrank\db %SRC%\cxbrank\db
mklink /d cxbrank\public %SRC%\cxbrank\public
mklink /d cxbrank\views %SRC%\cxbrank\views

mkdir revrank
mklink revrank\rackup.bat %SRC%\revrank\rackup.bat
mklink revrank\rake.bat %SRC%\revrank\rake.bat
mklink revrank\config.ru %SRC%\revrank\config.ru
mklink revrank\index.rb %SRC%\revrank\index.rb
mklink revrank\app.rb %SRC%\revrank\app.rb
mklink revrank\Gemfile %SRC%\revrank\Gemfile
mklink revrank\Gemfile.lock %SRC%\revrank\Gemfile.lock
mklink revrank\Rakefile %SRC%\revrank\Rakefile
mkdir revrank\config
copy %SRC%\revrank\config\config.yml revrank\config
copy %SRC%\revrank\config\database.yml revrank\config
mklink /d revrank\db %SRC%\revrank\db
mklink /d revrank\public %SRC%\revrank\public
mklink /d revrank\views %SRC%\revrank\views

cd %SRC%
