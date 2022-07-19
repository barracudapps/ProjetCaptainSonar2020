cd src

rm *.ozf

cd players

/Applications/Mozart2.app/Contents/Resources/bin/ozc -c *.oz
mv *.ozf ..

cd ..

/Applications/Mozart2.app/Contents/Resources/bin/ozc -c Input.oz
/Applications/Mozart2.app/Contents/Resources/bin/ozc -c PlayerManager.oz
/Applications/Mozart2.app/Contents/Resources/bin/ozc -c GUI.oz
/Applications/Mozart2.app/Contents/Resources/bin/ozc -c Main.oz
/Applications/Mozart2.app/Contents/Resources/bin/ozengine Main.ozf

cd ..
