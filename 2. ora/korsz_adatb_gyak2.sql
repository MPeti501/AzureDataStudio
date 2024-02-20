/*1
K�sz�ts�nk list�t arr�l, hogy melyik �gyf�l (LOGIN) h�nyszor rendelt
�sszesen. A lista tartalmazza a v�g�sszeget is. A list�t rendezz�k
a rendel�sek sz�ma szerint n�vekv� sorrendbe!
*/
SELECT [LOGIN], COUNT(*) AS 'DB'
FROM Rendeles
GROUP BY ROLLUP([LOGIN])
ORDER BY 2 

/*2
�tlagosan h�ny term�k van k�szleten kateg�ri�nk�nt (KAT_ID), 
rakt�rank�nt (RAKTAR_KOD), illetve mennyis�gi egys�genk�nt?
(szempontonk�nt k�l�n-k�l�n) Az �tlagot kerek�ts�k eg�szre!
A feladatot egy lek�rdez�ssel oldja meg!
*/
SELECT KAT_ID, RAKTAR_KOD, MEGYS, 
	   ROUND(AVG(keszlet), 0) AS '�tlagos k�szlet'
FROM Termek
GROUP BY GROUPING SETS((KAT_ID), (RAKTAR_KOD), (MEGYS))

/*3
K�sz�ts�nk list�t a megrendelt term�kek legkisebb �s 
legnagyobb egys�g�r�r�l sz�ll�t�si d�tum, azon bel�l sz�ll�t�si 
m�d szerinti bont�sban ! A lista csak a 2015 m�jusi sz�ll�t�sokat 
tartalmazza! Jelen�ts�k meg a r�sz�sszegeket �s a v�g�sszeget is!
*/
SELECT r.SZALL_DATUM, r.SZALL_MOD, 
       MIN(rt.EGYSEGAR) AS 'Legkisebb egys�g�r', 
	   MAX(rt.EGYSEGAR) AS 'Legnagyobb egys�g�r'
FROM Rendeles r JOIN Rendeles_tetel rt ON r.SORSZAM = rt.SORSZAM
WHERE r.SZALL_DATUM BETWEEN '2015.05.01' AND '2015.05.31'
GROUP BY ROLLUP(r.SZALL_DATUM, r.SZALL_MOD)
/*4
K�sz�ts�nk csoportot a term�kek lista�ra alapj�n a k�vetkez�k szerint:
Az "olcs�" term�kek legyenek azok, amelyek lista�ra 3000 alatt van.
A "dr�ga" term�kek legyenek az 5000 felettiek, a t�bbi legyen "k�zepes".
List�zzuk az egyes csoportokat, �s a csoportokba tartoz� term�kek 
darabsz�m�t! A lista jelen�tse meg a v�g�sszeget is!
*/
SELECT CASE WHEN LISTAAR < 3000 THEN 'olcs�'
            WHEN LISTAAR >5000 THEN 'dr�ga'
			ELSE 'k�zepes' END AS '�rkateg�ria',
	   COUNT(*) AS 'DB'
FROM Termek
GROUP BY ROLLUP(CASE WHEN LISTAAR < 3000 THEN 'olcs�'
            WHEN LISTAAR >5000 THEN 'dr�ga'
			ELSE 'k�zepes' END) 

/*5
List�zzuk a rendel�si t�telek sz�m�t rakt�rank�nt �ves bont�sban!
A list�ban a rakt�r neve, az �v �s a darabsz�m
jelenjen meg! A lista jelen�tse meg a r�sz�sszegeket �s a 
v�g�sszeget is! A v�g�sszeget megfelel�en jel�lj�k!
Az oszlopokat nevezz�k el �rtelemszer�en!
*/
SELECT IIF(GROUPING(ra.RAKTAR_NEV)=1,'�sszesen',ra.RAKTAR_NEV) 
         AS 'Rakt�r',
       YEAR(r.rend_datum) AS '�v', 
	   COUNT(*) AS 'DB'
FROM Rendeles r JOIN Rendeles_tetel rt ON r.SORSZAM = rt.SORSZAM
                JOIN Termek t ON rt.TERMEKKOD = t.TERMEKKOD
				JOIN Raktar ra ON t.RAKTAR_KOD = ra.RAKTAR_KOD
GROUP BY ROLLUP(ra.RAKTAR_NEV, YEAR(r.rend_datum))

/*6
K�sz�ts�nk list�t az �gyfelek adatair�l n�v szerinti sorrendben.
Minden sorban jelenjen meg a sorrend szerint el�z�, illetve
k�vetkez� �gyf�l neve is. Ha nincs el�z� vagy k�vetkez� �gyf�l, 
akkor a 'Nincs' jelenjen meg!
*/
SELECT *,
       LAG(NEV,1,'Nincs') OVER(Order by NEV) AS 'El�z� �gyf�l',
	   LEAD(NEV,1,'Nincs') OVER(Order by NEV) AS 'K�vetkez� �gyf�l'
FROM Ugyfel
ORDER BY NEV
/*7
K�sz�ts�nk lek�rdez�st, amely megmutatja, hogy melyik
term�kkateg�ri�ba h�ny term�k tartozik. A lista a kateg�ria nev�t
�s a darabsz�mot jelen�tse meg. A lista ne tartalmazzon duplik�lt
sorokat. A feladatot part�ci�k seg�ts�g�vel oldjuk meg!
*/
SELECT DISTINCT tk.KAT_NEV,
       COUNT(*) OVER(PARTITION BY t.KAT_ID) AS 'DB'
FROM Termekkategoria tk JOIN Termek t 
     ON tk.KAT_ID = t.KAT_ID
/*8
K�sz�ts�nk list�t a rendel�si t�telekr�l. Az egyes rendel�si 
t�teleket term�kenk�nt soroljuk be 4 oszt�lyba a rendel�s 
mennyis�ge alapj�n.Jelen�ts�k meg ezt az inform�ci�t is egy �j 
oszlopban, az oszlop neve legyen 'Mennyis�gi kateg�ria'. 
A lista csak a 100 Ft feletti egys�g�r� rendel�si t�teleket vegye figyelembe!
*/
SELECT *,
       NTILE(4) OVER(PARTITION BY TERMEKKOD 
	   ORDER BY MENNYISEG) AS 'Mennyis�gi kateg�ria'
FROM Rendeles_tetel
WHERE EGYSEGAR>100
/*9
List�zzuk a term�kek k�dj�t, megnevez�s�t, kateg�ri�j�nak nev�t,
�s lista�r�t. A list�t eg�sz�ts�k ki k�t �j oszloppal, amelyek 
a kateg�ria legolcs�bb, illetve legdr�g�bb term�k�nek �r�t 
tartalmazz�k. A k�t �j oszlop l�trehoz�s�n�l part�ci�kkal 
dolgozzunk!
*/
SELECT t.TERMEKKOD, t.MEGNEVEZES, t.KAT_ID, t.LISTAAR,
       FIRST_VALUE(t.LISTAAR) OVER(PARTITION BY t.KAT_ID
	   ORDER BY t.LISTAAR) AS 'Kateg�ria legkisebb �ra',
	   LAST_VALUE(t.LISTAAR) OVER(PARTITION BY t.KAT_ID
	   ORDER BY t.LISTAAR RANGE BETWEEN UNBOUNDED PRECEDING
	   AND UNBOUNDED FOLLOWING) AS 'Kateg�ria legnagyobb �ra'
FROM Termek t JOIN Termekkategoria tk ON t.KAT_ID = tk.KAT_ID

/*10
K�sz�ts�nk list�t a rendel�sekr�l. A lista legyen rendezve 
�gyfelenk�nt (LOGIN), azon bel�l a rendel�s d�tuma szerint. 
A list�hoz k�sz�ts�nk sorsz�moz�st is.
A sorsz�m a k�vetkez� form�ban jelenjen meg: sorsz�m_�v_login. 
Pl: 1_2015_adam1 
A sz�moz�s login-onk�nt, azon bel�l rendel�si �venk�nt kezd�dj�n �jra. 
A sorsz�m oszlop neve legyen Azonos�t�.
*/
SELECT CAST(ROW_NUMBER() OVER(PARTITION BY [LOGIN], YEAR(REND_DATUM) 
       ORDER BY REND_DATUM) AS nvarchar(5))+'_'
	   +CAST(YEAR(REND_DATUM) as nvarchar(4))+'-'+[LOGIN]
	   AS 'Azonos�t�', *
FROM Rendeles
ORDER BY [LOGIN], REND_DATUM

/*11
 K�sz�ts�nk list�t a term�kek adatair�l lista�r szerint n�vekv� 
 sorrenben! A lista jelen�tse meg k�t �j oszlopban a sorrend szerint
 el�z�, illetve k�vetkez� term�k lista�r�t is a term�k saj�t 
 kateg�ri�j�ban �s rakt�r�ban! Ahol nincs el�z� vagy k�vetkez� 
 �rt�k, ott 0 jelenjen meg!
 Az oszlopokat nevezz�k el �rtelemszer�en!
*/
SELECT *,
       LAG(LISTAAR, 1, 0) OVER(PARTITION BY KAT_ID, RAKTAR_KOD 
	   ORDER BY LISTAAR) 
	   AS 'El�z� lista�r ebben a kateg�ri�ban �s rakt�rban',
	   LEAD(LISTAAR, 1, 0) OVER(PARTITION BY KAT_ID, RAKTAR_KOD 
	   ORDER BY LISTAAR) 
	   AS 'K�vetkez� lista�r ebben a kateg�ri�ban �s rakt�rban'   
FROM Termek
ORDER BY LISTAAR

/*12
List�zzuk a term�kek k�dj�t, nev�t �s lista�r�t lista�r szerinti
sorrendben! Vegy�nk fel egy �j oszlopot Mozg��tlag n�ven, amely
minden esetben az aktu�lis term�k, az el�z�, �s a k�vetkez� term�k
�tlag�r�t tartalmazza! A mozg��tlagot kerek�ts�k k�t tizedesre!
*/
SELECT TERMEKKOD, MEGNEVEZES, LISTAAR,
       ROUND(AVG(LISTAAR) OVER(ORDER BY LISTAAR
	                ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING), 2)
	   AS 'Mozg��tlag'
FROM Termek
ORDER BY LISTAAR
/*13
K�sz�ts�nk list�t, amely a rendel�sek sorsz�m�t �s a rendel�s �rt�k�t
tartalmazza. A list�t eg�sz�ts�k ki egy �j oszloppal, amely minden
rendel�s eset�n addigi rendel�sek �rt�k�nek �sszeg�t tartalmazza (az
aktu�lisat is bele�rtve)! A list�t rendezz�k sorsz�m szerint 
n�vekv� sorrendbe. A lista ne tartalmazzon duplik�lt sorokat!
Nevezz�k el az oszlopokat �rtelemszer�en!
*/
SELECT DISTINCT SORSZAM, 
       SUM(MENNYISEG*EGYSEGAR) OVER(PARTITION BY SORSZAM) 
	   AS '�rt�k',
	   SUM(MENNYISEG*EGYSEGAR) OVER( 
	   ORDER BY SORSZAM RANGE BETWEEN UNBOUNDED PRECEDING 
	   AND CURRENT ROW)
	   AS 'Eddigi rendel�sek �sszege'
FROM Rendeles_tetel
ORDER BY SORSZAM

/*14
K�sz�ts�nk list�t a term�kek k�dj�r�l, nev�r�l, kateg�ria 
azonos�t�j�r�l, rakt�r azonos�t�j�r�l �s lista�r�r�l, valamint 
a term�k adott szempontok szerinti rangsorokban elfogalt 
helyez�seir�l. (Szempontonk�nt k�l�n oszlopban, a helyez�sekn�l
n�vekv� sorrendet felt�telezve). 
A szempontok a k�vetkez�k legyenek: lista�r, kateg�ria szerinti lista�r,
�s rakt�rk�d szerinti lista�r. Az oszlopokat nevezz�k el �rtelemszer�en.
A helyez�sek egyenl�s�g eset�n "s�r�n" k�vess�k egym�st. A lista
legyen rendezett kateg�ria azonos�t�, azon bel�l lista�r szerint!
*/
SELECT TERMEKKOD, MEGNEVEZES, KAT_ID, RAKTAR_KOD, LISTAAR,
       DENSE_RANK() OVER(ORDER BY LISTAAR) AS 'Helyez�s �r alapj�n',
	   RANK() OVER(PARTITION BY KAT_ID ORDER BY LISTAAR) 
	   AS 'Helyez�s �r alapj�n kateg�ri�n bel�l',
	   DENSE_RANK() OVER (PARTITION BY RAKTAR_KOD ORDER BY LISTAAR) 
	   AS 'Helyez�s �r alapj�n rakt�ron bel�l'
FROM Termek
ORDER BY KAT_ID, LISTAAR
/*15
K�sz�ts�nk list�t a rendel�si t�telekr�l, amely minden sor eset�n 
g�ngy�l�tve tartalmazza az �gyf�l adott rendel�si t�telig
megl�v� rendel�si t�teleinek �ssz�rt�k�t! Az �j oszlop neve legyen
Eddigi rendel�si t�telek �ssz�rt�ke! Az �gyf�l neve is jelenjen meg!
*/
SELECT rt.*,
       u.nev,
       SUM(rt.mennyiseg*rt.egysegar) 
	   OVER(PARTITION BY r.LOGIN ORDER BY rt.SORSZAM, termekkod 
	     RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
	   AS 'Eddigi rendel�si t�telek �ssz�rt�ke'
FROM Rendeles_tetel rt JOIN Rendeles r 
     ON rt.SORSZAM = r.SORSZAM
	 JOIN Ugyfel u ON r.LOGIN = u.LOGIN
--ORDER BY rt.SORSZAM, rt.TERMEKKOD