
@echo off

:: Where to download - CHANGE IT HERE
SET ROOT=C:\xampp\htdocs

:: WP variables - CHANGE IT HERE
SET LANGUAGE=pt_BR
SET DB_PREFIX=wp_
SET DB_USER=root
SET DB_PASS=
SET USER=admin
SET EMAIL=admin@admin.com
SET PASSWORD=admin

:: Github - CHANGE IT HERE
SET USERNAME="your-username"
SET TOKEN="your-personal-token"

:: Base theme - CHANGE IT HERE
SET BASETHEME_NAME=base-theme
SET BASETHEME_REMOTE=git@github.com:victormattosvm/base-theme.git


:: ------------------------------------------------------------------------------

:: Get info
set /p NAME=Project folder: 
set /p CREATE_REPO=Create repo on Github? [y/n]: 

if /I "%CREATE_REPO%" EQU "y" (
    set /p REPO=Repo name: 
    set /p DESCRIPTION=Description: 
)

set /P WOO=Install and activate woocommerce? [y/n]:  
set /p NPM=Call NPM? [y/n]: 
set /p GULP=Call gulp? [y/n]: 



echo.
echo --------------------------------------------------------------------------------
echo Downloading and installing wordpress...
echo.

:: Navigate to the projects folder
cd %ROOT%

:: Create directory
mkdir %NAME%
    
:: Go into directory
cd %NAME%
    
:: Download WordPress
call wp core download --locale=%LANGUAGE%
    
:: Generate wp-config
:: We need to escape the php we pass in to the wp-config or we will get syntax errors
(echo define^^^('WP_AUTO_UPDATE_CORE', false^^^);^
& echo define^^^('WP_DEBUG', true^^^);^
& echo define^^^('DISALLOW_FILE_MODS', false^^^);^
& echo define^^^('DISALLOW_FILE_EDIT', false ^^^);) | wp core config --dbname=%DB_PREFIX%%NAME% --dbuser=%DB_USER% --dbpass=%DB_PASS% --extra-php

:: Create DB
call wp db create
    
:: Install wordpress
call wp core install --url="http://localhost/%NAME%" --title="%NAME%" --admin_user="%USER%" --admin_password="%PASSWORD%" --admin_email="%EMAIL%"
    
echo.
echo --------------------------------------------------------------------------------
echo Removing default plugins...
echo.
    
:: Delete akismet and hello dolly
call wp plugin delete akismet
call wp plugin delete hello

echo.
echo --------------------------------------------------------------------------------
echo Cloning base theme
echo.


:: Go to themes folder
cd %ROOT%/%NAME%/wp-content/themes/


:: Clone the theme from github
call git clone --depth 1 %BASETHEME_REMOTE%

ren %BASETHEME_NAME% %NAME%


REM :: Activate the theme
call wp theme activate %NAME%

:: Remove all default themes
call wp theme delete twentysixteen
call wp theme delete twentyseventeen
call wp theme delete twentynineteen
call wp theme delete twentytwenty


REM REM :: Activate plugin
REM REM call wp plugin activate tecnossauro-new-project
REM REM call wp plugin install classic-editor --activate
REM REM call wp plugin install admin-menu-editor --activate
REM REM call wp plugin install advanced-custom-fields --activate
REM REM call wp plugin activate advanced-custom-fields-pro
REM REM call wp plugin install contact-form-7 --activate
REM REM call wp plugin install disable-comments --activate


REM REM call wp plugin deactivate tecnossauro-new-project
REM REM call wp plugin delete tecnossauro-new-project

if /I "%WOO%" EQU "y" (
    call wp plugin install woocommerce --activate
)

:: set pretty urls
:: we set pretty urls here to give it some time to complete before flushing the permalinks later
:: unfortunatly call does not work on this command so we have to open and run in a seperate cmd window
start cmd /c wp rewrite structure /%%postname%%/ --hard

:: Clear Window
:: cls

:: unfortunatly call does not work on this command so we have to open and run in a seperate cmd window
start cmd /c wp rewrite flush --hard


REM :: Run package installers if your theme requires it
if /I "%NPM%" EQU "y" (
    cd %ROOT%/%NAME%/wp-content/themes/%BASETHEME_NAME%
    call npm install
)


if /I "%CREATE_REPO%" EQU "y" (
    call curl -u %USERNAME%:%TOKEN% https://api.github.com/user/repos -d "{\"name\":\"%REPO%\",\"description\":\"%DESCRIPTION%\",\"private\":true}"


    cd %ROOT%/%NAME%/wp-content/themes/%NAME%
    rmdir /s /q .git

    :: Change remote url and push
    call git init
    call git remote add origin git@github.com:%USERNAME%/%REPO%.git
    call git add .
    call git commit -m "First commit"
    call git push -u origin master

    echo.
    echo --------------------------------------------------------------------------------
    echo Repository created!
    echo.


)



echo.
echo.
echo Wordpress has been installed!
echo.
echo User: %USER%
echo Pass: %PASSWORD%
echo.

echo have a nice day :)

echo.

:: Add to clipboard
echo User: %USER% Pass: %PASSWORD% | clip
    
:: start the project in browser
start http://localhost/%NAME%


if /I "%GULP%" EQU "y" (
    call gulp dev
)

pause
    
goto:eof

:fatal
echo.
echo --------------------------------------------------------------------------------
echo Please specify a name for your WordPress Install
echo.
goto:eof
    
:END
