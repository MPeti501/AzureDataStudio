/*1
Készítsünk listát arról, hogy melyik ügyfél (LOGIN) hányszor rendelt
összesen. A lista tartalmazza a végösszeget is. A listát rendezzük
a rendelések száma szerint növekvõ sorrendbe!
*/
SELECT [LOGIN], COUNT(*) AS 'DB'
FROM Rendeles
GROUP BY ROLLUP([LOGIN])
ORDER BY 2 

/*2
Átlagosan hány termék van készleten kategóriánként (KAT_ID), 
raktáranként (RAKTAR_KOD), illetve mennyiségi egységenként?
(szempontonként külön-külön) Az átlagot kerekítsük egészre!
A feladatot egy lekérdezéssel oldja meg!
*/
SELECT KAT_ID, RAKTAR_KOD, MEGYS, 
	   ROUND(AVG(keszlet), 0) AS 'Átlagos készlet'
FROM Termek
GROUP BY GROUPING SETS((KAT_ID), (RAKTAR_KOD), (MEGYS))

/*3
Készítsünk listát a megrendelt termékek legkisebb és 
legnagyobb egységáráról szállítási dátum, azon belül szállítási 
mód szerinti bontásban ! A lista csak a 2015 májusi szállításokat 
tartalmazza! Jelenítsük meg a részösszegeket és a végösszeget is!
*/
SELECT r.SZALL_DATUM, r.SZALL_MOD, 
       MIN(rt.EGYSEGAR) AS 'Legkisebb egységár', 
	   MAX(rt.EGYSEGAR) AS 'Legnagyobb egységár'
FROM Rendeles r JOIN Rendeles_tetel rt ON r.SORSZAM = rt.SORSZAM
WHERE r.SZALL_DATUM BETWEEN '2015.05.01' AND '2015.05.31'
GROUP BY ROLLUP(r.SZALL_DATUM, r.SZALL_MOD)
/*4
Készítsünk csoportot a termékek listaára alapján a következõk szerint:
Az "olcsó" termékek legyenek azok, amelyek listaára 3000 alatt van.
A "drága" termékek legyenek az 5000 felettiek, a többi legyen "közepes".
Listázzuk az egyes csoportokat, és a csoportokba tartozó termékek 
darabszámát! A lista jelenítse meg a végösszeget is!
*/
SELECT CASE WHEN LISTAAR < 3000 THEN 'olcsó'
            WHEN LISTAAR >5000 THEN 'drága'
			ELSE 'közepes' END AS 'Árkategória',
	   COUNT(*) AS 'DB'
FROM Termek
GROUP BY ROLLUP(CASE WHEN LISTAAR < 3000 THEN 'olcsó'
            WHEN LISTAAR >5000 THEN 'drága'
			ELSE 'közepes' END) 

/*5
Listázzuk a rendelési tételek számát raktáranként éves bontásban!
A listában a raktár neve, az év és a darabszám
jelenjen meg! A lista jelenítse meg a részösszegeket és a 
végösszeget is! A végösszeget megfelelõen jelöljük!
Az oszlopokat nevezzük el értelemszerûen!
*/
SELECT IIF(GROUPING(ra.RAKTAR_NEV)=1,'Összesen',ra.RAKTAR_NEV) 
         AS 'Raktár',
       YEAR(r.rend_datum) AS 'Év', 
	   COUNT(*) AS 'DB'
FROM Rendeles r JOIN Rendeles_tetel rt ON r.SORSZAM = rt.SORSZAM
                JOIN Termek t ON rt.TERMEKKOD = t.TERMEKKOD
				JOIN Raktar ra ON t.RAKTAR_KOD = ra.RAKTAR_KOD
GROUP BY ROLLUP(ra.RAKTAR_NEV, YEAR(r.rend_datum))

/*6
Készítsünk listát az ügyfelek adatairól név szerinti sorrendben.
Minden sorban jelenjen meg a sorrend szerint elõzõ, illetve
következõ ügyfél neve is. Ha nincs elõzõ vagy következõ ügyfél, 
akkor a 'Nincs' jelenjen meg!
*/
SELECT *,
       LAG(NEV,1,'Nincs') OVER(Order by NEV) AS 'Elõzõ ügyfél',
	   LEAD(NEV,1,'Nincs') OVER(Order by NEV) AS 'Következõ ügyfél'
FROM Ugyfel
ORDER BY NEV
/*7
Készítsünk lekérdezést, amely megmutatja, hogy melyik
termékkategóriába hány termék tartozik. A lista a kategória nevét
és a darabszámot jelenítse meg. A lista ne tartalmazzon duplikált
sorokat. A feladatot partíciók segítségével oldjuk meg!
*/
SELECT DISTINCT tk.KAT_NEV,
       COUNT(*) OVER(PARTITION BY t.KAT_ID) AS 'DB'
FROM Termekkategoria tk JOIN Termek t 
     ON tk.KAT_ID = t.KAT_ID
/*8
Készítsünk listát a rendelési tételekrõl. Az egyes rendelési 
tételeket termékenként soroljuk be 4 osztályba a rendelés 
mennyisége alapján.Jelenítsük meg ezt az információt is egy új 
oszlopban, az oszlop neve legyen 'Mennyiségi kategória'. 
A lista csak a 100 Ft feletti egységárú rendelési tételeket vegye figyelembe!
*/
SELECT *,
       NTILE(4) OVER(PARTITION BY TERMEKKOD 
	   ORDER BY MENNYISEG) AS 'Mennyiségi kategória'
FROM Rendeles_tetel
WHERE EGYSEGAR>100
/*9
Listázzuk a termékek kódját, megnevezését, kategóriájának nevét,
és listaárát. A listát egészítsük ki két új oszloppal, amelyek 
a kategória legolcsóbb, illetve legdrágább termékének árát 
tartalmazzák. A két új oszlop létrehozásánál partíciókkal 
dolgozzunk!
*/
SELECT t.TERMEKKOD, t.MEGNEVEZES, t.KAT_ID, t.LISTAAR,
       FIRST_VALUE(t.LISTAAR) OVER(PARTITION BY t.KAT_ID
	   ORDER BY t.LISTAAR) AS 'Kategória legkisebb ára',
	   LAST_VALUE(t.LISTAAR) OVER(PARTITION BY t.KAT_ID
	   ORDER BY t.LISTAAR RANGE BETWEEN UNBOUNDED PRECEDING
	   AND UNBOUNDED FOLLOWING) AS 'Kategória legnagyobb ára'
FROM Termek t JOIN Termekkategoria tk ON t.KAT_ID = tk.KAT_ID

/*10
Készítsünk listát a rendelésekrõl. A lista legyen rendezve 
ügyfelenként (LOGIN), azon belül a rendelés dátuma szerint. 
A listához készítsünk sorszámozást is.
A sorszám a következõ formában jelenjen meg: sorszám_év_login. 
Pl: 1_2015_adam1 
A számozás login-onként, azon belül rendelési évenként kezdõdjön újra. 
A sorszám oszlop neve legyen Azonosító.
*/
SELECT CAST(ROW_NUMBER() OVER(PARTITION BY [LOGIN], YEAR(REND_DATUM) 
       ORDER BY REND_DATUM) AS nvarchar(5))+'_'
	   +CAST(YEAR(REND_DATUM) as nvarchar(4))+'-'+[LOGIN]
	   AS 'Azonosító', *
FROM Rendeles
ORDER BY [LOGIN], REND_DATUM

/*11
 Készítsünk listát a termékek adatairól listaár szerint növekvõ 
 sorrenben! A lista jelenítse meg két új oszlopban a sorrend szerint
 elõzõ, illetve következõ termék listaárát is a termék saját 
 kategóriájában és raktárában! Ahol nincs elõzõ vagy következõ 
 érték, ott 0 jelenjen meg!
 Az oszlopokat nevezzük el értelemszerûen!
*/
SELECT *,
       LAG(LISTAAR, 1, 0) OVER(PARTITION BY KAT_ID, RAKTAR_KOD 
	   ORDER BY LISTAAR) 
	   AS 'Elõzõ listaár ebben a kategóriában és raktárban',
	   LEAD(LISTAAR, 1, 0) OVER(PARTITION BY KAT_ID, RAKTAR_KOD 
	   ORDER BY LISTAAR) 
	   AS 'Következõ listaár ebben a kategóriában és raktárban'   
FROM Termek
ORDER BY LISTAAR

/*12
Listázzuk a termékek kódját, nevét és listaárát listaár szerinti
sorrendben! Vegyünk fel egy új oszlopot Mozgóátlag néven, amely
minden esetben az aktuális termék, az elõzõ, és a következõ termék
átlagárát tartalmazza! A mozgóátlagot kerekítsük két tizedesre!
*/
SELECT TERMEKKOD, MEGNEVEZES, LISTAAR,
       ROUND(AVG(LISTAAR) OVER(ORDER BY LISTAAR
	                ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING), 2)
	   AS 'Mozgóátlag'
FROM Termek
ORDER BY LISTAAR
/*13
Készítsünk listát, amely a rendelések sorszámát és a rendelés értékét
tartalmazza. A listát egészítsük ki egy új oszloppal, amely minden
rendelés esetén addigi rendelések értékének összegét tartalmazza (az
aktuálisat is beleértve)! A listát rendezzük sorszám szerint 
növekvõ sorrendbe. A lista ne tartalmazzon duplikált sorokat!
Nevezzük el az oszlopokat értelemszerûen!
*/
SELECT DISTINCT SORSZAM, 
       SUM(MENNYISEG*EGYSEGAR) OVER(PARTITION BY SORSZAM) 
	   AS 'Érték',
	   SUM(MENNYISEG*EGYSEGAR) OVER( 
	   ORDER BY SORSZAM RANGE BETWEEN UNBOUNDED PRECEDING 
	   AND CURRENT ROW)
	   AS 'Eddigi rendelések összege'
FROM Rendeles_tetel
ORDER BY SORSZAM

/*14
Készítsünk listát a termékek kódjáról, nevérõl, kategória 
azonosítójáról, raktár azonosítójáról és listaáráról, valamint 
a termék adott szempontok szerinti rangsorokban elfogalt 
helyezéseirõl. (Szempontonként külön oszlopban, a helyezéseknél
növekvõ sorrendet feltételezve). 
A szempontok a következõk legyenek: listaár, kategória szerinti listaár,
és raktárkód szerinti listaár. Az oszlopokat nevezzük el értelemszerûen.
A helyezések egyenlõség esetén "sûrûn" kövessék egymást. A lista
legyen rendezett kategória azonosító, azon belül listaár szerint!
*/
SELECT TERMEKKOD, MEGNEVEZES, KAT_ID, RAKTAR_KOD, LISTAAR,
       DENSE_RANK() OVER(ORDER BY LISTAAR) AS 'Helyezés ár alapján',
	   RANK() OVER(PARTITION BY KAT_ID ORDER BY LISTAAR) 
	   AS 'Helyezés ár alapján kategórián belül',
	   DENSE_RANK() OVER (PARTITION BY RAKTAR_KOD ORDER BY LISTAAR) 
	   AS 'Helyezés ár alapján raktáron belül'
FROM Termek
ORDER BY KAT_ID, LISTAAR
/*15
Készítsünk listát a rendelési tételekrõl, amely minden sor esetén 
göngyölítve tartalmazza az ügyfél adott rendelési tételig
meglévõ rendelési tételeinek összértékét! Az új oszlop neve legyen
Eddigi rendelési tételek összértéke! Az ügyfél neve is jelenjen meg!
*/
SELECT rt.*,
       u.nev,
       SUM(rt.mennyiseg*rt.egysegar) 
	   OVER(PARTITION BY r.LOGIN ORDER BY rt.SORSZAM, termekkod 
	     RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
	   AS 'Eddigi rendelési tételek összértéke'
FROM Rendeles_tetel rt JOIN Rendeles r 
     ON rt.SORSZAM = r.SORSZAM
	 JOIN Ugyfel u ON r.LOGIN = u.LOGIN
--ORDER BY rt.SORSZAM, rt.TERMEKKOD