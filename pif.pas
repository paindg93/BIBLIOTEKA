unit PiF;

interface
uses
  Classes, SysUtils, CRT, Graph, DOS;
const
  dl_pesel = 11; //stala okreslajaca dlugosc pesla
  dl_nazwy = 30; //stala okresla dlugosc pol imie, nazwisko itp.
  odleglosc_od_prawej_krawedzi  = 40;//stale okreslajaca polozenie dodatkowych menu
  odleglosc_od_dolnej_krawedzi  = 4; //
type
  pole = string[dl_nazwy]; //okreslenie dlugosci pol
  pole2 = string[dl_pesel]; //okreslenie dlugosci pola pesel
  wsk_uzytkownik = ^uzytkownik; //wskaznik na rekord uzytkownik
  wsk_ksiazka = ^ksiazka;      //wskaznik na rekor ksiazka
  uzytkownik = record       //rekord uzytkownika
                  imie, nazwisko : pole;
                  pesel : pole2;
                  ilosc_wypozyczonych_ksiazek : byte;
                  nastepny : wsk_uzytkownik;
                  poprzedni : wsk_uzytkownik;
                  glowa_ksiazek : wsk_ksiazka;
              end;
  ksiazka = record          //rekord ksiazki
              autor, tytul, wydawnictwo, rok_miejsce_wydania : pole;
              dostepnosc : byte;
              nastepny : wsk_ksiazka;
              poprzedni : wsk_ksiazka;
              wsk_na_org : wsk_ksiazka;
            end;

var
  g_ksiazki : wsk_ksiazka;//wskaznik na glowe ksiazki
  g_uzytkownicy : wsk_uzytkownik; //wskaznik na glowe uzytkownika


function licz_ile_ksiazek(glowa: wsk_ksiazka) : integer;
function licz_ile_uzytkownikow(glowa: wsk_uzytkownik): integer;
procedure brak_danych;
procedure dodaj (var g_ksiazki: wsk_ksiazka; var g_uzytkownicy : wsk_uzytkownik; var znak : char);
procedure dodaj_ksiazke (var glowa : wsk_ksiazka; opcja : byte; var el: wsk_ksiazka);
procedure dodaj_uzytkownika (var glowa : wsk_uzytkownik);
procedure info;
procedure menu (var g_ksiazki: wsk_ksiazka; var g_uzytkownicy : wsk_uzytkownik);
procedure przypisz_wskaznik_na_orginal(var element : wsk_ksiazka; lista_ksiazek : wsk_ksiazka);
procedure rysuj;
procedure sortuj_ksiazki (var glowa : wsk_ksiazka);
procedure sortuj_uzytkownikow (var glowa : wsk_uzytkownik);
procedure sprawdz_folder(nazwa : string);
procedure usun_ksiazke (var element_k : wsk_ksiazka;  opcja : byte);
procedure usun_ksiazki_uzytkownika (var glowa : wsk_ksiazka; var lista_ksiazek_uzytkownika  :wsk_ksiazka; opcja : byte);
procedure wczytaj_z_pliku(var g_uzytkownicy : wsk_uzytkownik; var g_ksiazki : wsk_ksiazka);
procedure wyswietl(var g_ksiazki : wsk_ksiazka; var g_uzytkownicy : wsk_uzytkownik; var znak : char);
procedure wyswietl_ksiazki(var glowa : wsk_ksiazka; opcja, opcja2 : byte; var lista_ksiazek_uzytkownika : wsk_ksiazka; var znak : char);
procedure wyswietl_uzytkownikow( var glowa : wsk_uzytkownik ; var lista : wsk_ksiazka; var znak : char);
procedure zapisz_do_plikow(glowa_uzytkownicy : wsk_uzytkownik; glowa_ksiazki : wsk_ksiazka);
procedure zwolnij_pamiec (var glowa_ksiazki : wsk_ksiazka; var glowa_uzytkownikow : wsk_uzytkownik);

implementation
procedure usun_ksiazke_uzytkownikowi (var element: wsk_ksiazka);
{Procedura szuka i usuwa ksiazke z listy wypozyczonych ksiazek u wybranego uzytkownika.
Jako parametr wyslany przez zmienna przyjmuje wskaznik na wybrany element, ktoremu
przywrocona ma zostac dostepnosc, oraz wskaznik na liste ksiazek wypozycznych przez
jednego uzytkownika.}
var
  tmp : wsk_ksiazka;
begin
  tmp:=element;
  if tmp<>nil then //jesli lista istnieje
    begin
      tmp^.wsk_na_org^.dostepnosc:=1;
      tmp^.wsk_na_org:=nil;
      if (tmp^.poprzedni<>nil) and (tmp^.nastepny<>nil) then //jezeli nastepny i poprzedni element istnieje
        begin
          tmp^.poprzedni^.nastepny:=tmp^.nastepny;
          tmp^.nastepny^.poprzedni:=tmp^.poprzedni;
        end
      else
        if tmp^.poprzedni<>nil then //jesli poprzedni istnieje
          begin
          tmp:=tmp^.poprzedni;
          tmp:=nil;
          end
        else
          if tmp^.nastepny<>nil then //jesli natepny istnieje
            begin
            tmp:=tmp^.nastepny;
            tmp:=nil;
            end
          else tmp:=nil; //jesli jest tylko jeden
    end;
  if tmp<>nil then
    while tmp^.poprzedni<>nil do
      tmp:=tmp^.poprzedni; //wroc na poczatek listy
  element:=tmp; //przypisz wskaznik na nowa glowe
  end;

procedure usun_ksiazke (var element_k : wsk_ksiazka;  opcja : byte);
{Uwuwanie ksiazki z biblioteki dla opcja=0, badz z listy przypisacnej uzytkownikowi
opcja=1. Jako parametr przyjmuje wskaznik wyslany przez zmienna na dana ksiazke.
Jako parametr przez wartosc przyjmuje wartosc sterujaca procedura}
var
 tmp : wsk_ksiazka;
begin
 if (element_k^.nastepny<>nil) and (element_k^.poprzedni<>nil) then //jesli nastepny i porzedni element istnieje
   begin
     tmp:=element_k;
     element_k^.poprzedni^.nastepny:=element_k^.nastepny;
     element_k^.nastepny^.poprzedni:=element_k^.poprzedni;
   end
 else
   if (element_k^.nastepny<>nil) then //jesli nastepny element istnieje
     begin
       tmp:=element_k;
       element_k:=element_k^.nastepny;
       element_k^.poprzedni:=nil;
     end
   else
     if (element_k^.poprzedni<>nil) then //jesli poprzedni element istnieje
       begin
         tmp:=element_k;
         element_k:=element_k^.poprzedni;
         element_k^.nastepny:=nil;
       end
       else //jesli jest tylko jeden element na liscie
         begin
         tmp:=element_k;
         element_k:=nil;
         end;
 if opcja=1 then
   begin
     tmp^.wsk_na_org^.dostepnosc:=1;
     tmp^.wsk_na_org:=nil;
     dispose(tmp);
   end;

 if opcja = 0 then
   dispose(tmp); //jesli usuwamy ksiazke z biblioteki, wyczysc miejsce przez nia zajmowane
 tmp:=nil; //zeruj wskaznik pomocniczy
end;

procedure usun_ksiazki_uzytkownika (var glowa : wsk_ksiazka; var lista_ksiazek_uzytkownika :wsk_ksiazka; opcja : byte);
{Procedura usuwa wszystkie ksiazki przypisane uzytkownikowi i przywraca dostepnosc na liscie
ksiazek biblioteki. Jako parametry wyslane przez zmienna przyjmuje wskazniki na
poczatek listy ksiazek biblioteki, wskaznik na glowe ksiazek aktualnie wybranego
 uzytkownika. Jako parametr dodatkowy przyjmuje opcje wyslana przez wartosc sterujaca
 dalszymi wywolaniami.}
var
  tmp1 : wsk_ksiazka;
begin
  while lista_ksiazek_uzytkownika<> nil do //jesli przyslany wskaznik nie jest pusty
   begin
     tmp1:=glowa;
     if tmp1<>nil then //jesli lista ksiazek istnieje
       if tmp1^.nastepny<>nil then //jesli nastpeny element na liscie istnieje
         while (tmp1^.tytul<>lista_ksiazek_uzytkownika^.tytul) and (tmp1^.nastepny<>nil) do
          tmp1:=tmp1^.nastepny;
         //dopoki tytuly sie nie zagadzaja i nastepny element istnieje, przejdz do nastepnego elementu
     if tmp1<>nil then tmp1^.dostepnosc:=1; //jesli element listy istnieje przywroc dostepnosc
     usun_ksiazke(lista_ksiazek_uzytkownika,opcja); //usun ksiazke z listy ksiazek przypisanych uzytkownikowi
   end;
  tmp1:=nil;
end;

function licz_ile_uzytkownikow(glowa : wsk_uzytkownik) : integer;
{Funkcja liczy ilosc uzytkownikow na liscie. Wywolana z wskaznikiem wyslanym przez wartosc
na poczatek listy ksiazek. Jako wartosc zwraca ilosc uzytkownikow}
var
  i : integer;
begin
  i:=0;
  while(glowa<>nil) do //dopoki element istnieje
    begin
      glowa:=glowa^.nastepny; //przejdz do elementu nastepnego
      inc(i); //dodaj jedynke do aktualnej liczby ksiazek
    end;
  licz_ile_uzytkownikow:=i; //zwroc liczbe uzytkownikow
end;

function licz_ile_ksiazek(glowa: wsk_ksiazka) : integer;
{Procedura liczy ilosc ksiazek na liscie. Wywolana z wskaznikiem wyslanym przez wartosc
na poczatek listy ksiazek, oraz z licznikiem wysalnym przez zmienna}
var
  i : integer; //licznik
begin
  i:=0;
  if glowa<>nil then
    while glowa^.poprzedni<>nil do
      glowa:=glowa^.poprzedni;
  while(glowa<>nil) do //dopoki element istnieje
    begin
      glowa:=glowa^.nastepny; //przejdz do elementu nastepnego
      inc(i); //dodaj jedynke do aktualnej liczby ksiazek
    end;
  licz_ile_ksiazek:=i;
end;

procedure sortuj_uzytkownikow (var glowa : wsk_uzytkownik);
{Procedura sortujaca liste uzytkownikow wedlug nazwisk. Wywyalana z wskaznikiem wyslanym
przez zmienna na pcozatek listy ksiazek}
var
  tmp, tmp2, tmp3: wsk_uzytkownik;
  i, j, k : integer;
begin
  i:=licz_ile_uzytkownikow(glowa);//licz ile elementow w liscie
  tmp:=glowa; //zapamietanie wskaznika na pierwszy element
  if i>=2 then //jesli jest wiecej niz jeden element, przejdz do sortowania babelkowego
    for j:=0 to i-1 do
      begin
        for k:=0 to i-1 do
          begin
            if(tmp^.nastepny<>nil) then //jesli nasteny element istnieje
              if (tmp^.nazwisko>tmp^.nastepny^.nazwisko) then //jesli aktualne nazwisko jest wiekszw niz nastepny nazwisko
                begin
                  tmp3:=tmp^.nastepny^.nastepny;
                  tmp2:=tmp^.nastepny;
                  tmp2^.poprzedni:=tmp^.poprzedni;
                  if tmp^.poprzedni<>nil then tmp^.poprzedni^.nastepny:=tmp^.nastepny;
                  //jesli poprzedni element istnieje, jego wskaznik na nastepny element, wskazuje na aktualnie nastepny element
                  tmp^.poprzedni:=tmp2;
                  tmp^.nastepny:=tmp3;
                  tmp2^.nastepny:=tmp;
                  if tmp3<>nil then tmp3^.poprzedni:=tmp; //jesli nastepny element istnieje, jego wskaznik na poprzedni element wskazuje na aktualny
                end
              else tmp:=tmp^.nastepny;  //jesli nazwisko nie jest wieksze przejdz na natepny element
          end;
        while(tmp^.poprzedni<>nil) do
          tmp:=tmp^.poprzedni; //przejdz na poczatek listy
      end;
  glowa:=tmp; //przypisz wskaznik na nowa glowe
end;

procedure sortuj_ksiazki (var glowa : wsk_ksiazka);
{Procedura sortujaca liste ksiazek wedlug tytulow. Wywyalana z wskaznikiem wyslanym
przez zmienna na pcozatek listy ksiazek}
var
  tmp, tmp2, tmp3 : wsk_ksiazka;
  i, j, k : integer;
begin
  i:=licz_ile_ksiazek(glowa); //licz ile elementow w liscie
  tmp:=glowa; //zapamietanie wskaznika na pierwszy element
  if i>=2 then //jesli jest wiecej niz jeden element, przejdz do sortowania babelkowego
    for j:=0 to i-1 do
      begin
        for k:=0 to i-1 do
          begin
            if(tmp^.nastepny<>nil) then //jesli nasteny element istnieje
              if (tmp^.tytul>tmp^.nastepny^.tytul ) then //jesli aktualny tytul jest wiekszy niz nastepny tytul
              begin
                tmp3:=tmp^.nastepny^.nastepny;
                tmp2:=tmp^.nastepny;
                tmp2^.poprzedni:=tmp^.poprzedni;
                if tmp^.poprzedni<>nil then
                  tmp^.poprzedni^.nastepny:=tmp^.nastepny; //jesli poprzedni element istnieje, jego wskaznik na nastepny element, wskazuje na aktualnie nastepny element
                tmp^.poprzedni:=tmp2;
                tmp^.nastepny:=tmp3;
                tmp2^.nastepny:=tmp;
                if tmp3<>nil then
                  tmp3^.poprzedni:=tmp; //jesli nastepny element istnieje, jego wskaznik na poprzedni element wskazuje na aktualny
              end
              else tmp:=tmp^.nastepny; //jesli tytul nie jest wiekszy przejdz na natepny element
          end;
        while(tmp^.poprzedni<>nil) do tmp:=tmp^.poprzedni;//przejdz na poczatek listy
      end;
  glowa:=tmp; //przypisz wskaznik na nowa glowe
end;

procedure dodaj_uzytkownika (var glowa : wsk_uzytkownik);
{Procedura dodaje noweg użytkownika do programu. Jako parametr przyjmuje wskaznik na glowe listy
uzytkownikow. Dodaje uzytkownika wedlug nazwiska}
    function zbierz_dane_uzytkownika (var imie, nazwisko : pole; var pesel : pole2) : wsk_uzytkownik;
    {Funkcja zbiera informacje na temat dodawanego elementu. Zwraca adres na zedytowany element.
    Jak parametr przyjumje imie, nazwisko i pesel wykorzystane po wyjsciu z funkcji.}
    var
      tmp : wsk_uzytkownik;
    begin
      new(tmp);
      clrscr;
      gotoxy(2,2);
      write('Podaj nazwisko: ');
      readln(nazwisko);
      nazwisko:=upcase(nazwisko);
      if nazwisko='' then
        nazwisko:=' ';
      gotoxy(2,3);
      write('Podaj imie: ');
      readln(imie);
      imie:=upcase(imie);
      if imie='' then
        imie:=' ';
      gotoxy(2,4);
      write('Podaj pesel: ');
      readln(pesel);
      if pesel='' then
        pesel:=' ';
      tmp^.nazwisko:=nazwisko;
      tmp^.imie:=imie;
      tmp^.pesel:=pesel;
      tmp^.glowa_ksiazek:=nil;
      tmp^.ilosc_wypozyczonych_ksiazek := 0;
      zbierz_dane_uzytkownika:=tmp;
    end;

var
  tmp : wsk_uzytkownik;
  imie, nazwisko : pole;
  pesel : pole2;
begin
  tmp:=zbierz_dane_uzytkownika(imie,nazwisko,pesel);
  if (glowa = NIL) then
    begin
      tmp^.nastepny:=nil;
      glowa:=tmp;
      glowa^.poprzedni:=nil;
    end
  else
    if glowa^.nazwisko>nazwisko then
      begin
        tmp^.poprzedni:=glowa^.poprzedni;
        glowa^.poprzedni:=tmp;
        tmp^.nastepny:=glowa;
        glowa:=tmp;
      end
    else
      begin
        while (glowa^.nastepny<>nil) and (glowa^.nastepny^.nazwisko<nazwisko) do glowa:=glowa^.nastepny;
        tmp^.nastepny:=glowa^.nastepny;
        glowa^.nastepny:=tmp;
        tmp^.poprzedni:=glowa;
        glowa:=tmp;
      end;
  while (glowa^.nastepny<>nil) do glowa:=glowa^.nastepny;
  glowa^.nastepny:=nil;
  while (glowa^.poprzedni<>nil) do glowa:=glowa^.poprzedni;
  glowa^.poprzedni:=nil;
end;

procedure dodaj_ksiazke (var glowa : wsk_ksiazka; opcja : byte; var el: wsk_ksiazka);
{procedura dodaje nowa ksiazke do biblioteki. Paramtery : wskaznik na glowe  listy ksiazek,
opcje sterujaca dodanie ksiazki do biblioteki/uzytkownika, jesli do uzytkownika, dodatkowo,
wskaznik na ksiazke do dodania}
  function zbierz_dane_ksiazki (var tytul, autor, wydawnictwo, rok_miejsce_wydania : pole) : wsk_ksiazka;
  {Funkcja zbiera dane książki. Zwraca wskanik na zmieniony element}
  var
    tmp : wsk_ksiazka;
  begin
    clrscr;
    gotoxy(2,2);
    write('Podaj tytul: ');
    readln(tytul);
    tytul:=upcase(tytul);
    if tytul='' then
      tytul:=' ';
    gotoxy(2,3);
    write('Podaj autora: ');
    readln(autor);
    autor:=upcase(autor);
    if autor='' then
      autor:=' ';
    gotoxy(2,4);
    write('Podaj wydawnictwo: ');
    readln(wydawnictwo);
    wydawnictwo:=upcase(wydawnictwo);
    if wydawnictwo='' then
      wydawnictwo:=' ';
    gotoxy(2,5);
    write('Podaj rok i miejsce wydania: ');
    readln(rok_miejsce_wydania);
    if rok_miejsce_wydania='' then
      rok_miejsce_wydania:=' ';
    new(tmp);
    tmp^.tytul:=tytul;
    tmp^.autor:=autor;
    tmp^.wydawnictwo:=wydawnictwo;
    tmp^.rok_miejsce_wydania:=rok_miejsce_wydania;
    tmp^.dostepnosc:=1;
    zbierz_dane_ksiazki:=tmp;
  end;

  procedure dodaj_ksiazke_do_biblioteki (var glowa : wsk_ksiazka);//dodanie ksiazki do biblioteki
  var
    tmp : wsk_ksiazka;
    tytul, autor, wydawnictwo, rok_miejsce_wydania : pole;
  begin
    tmp:=zbierz_dane_ksiazki(tytul,autor,wydawnictwo,rok_miejsce_wydania);
    if (glowa = NIL) then
    begin
      tmp^.nastepny:=nil;
      glowa:=tmp;
      glowa^.poprzedni:=nil;
    end
  else
    if glowa^.tytul>tytul then
      begin
        tmp^.poprzedni:=glowa^.poprzedni;
        glowa^.poprzedni:=tmp;
        tmp^.nastepny:=glowa;
        glowa:=tmp;
      end
    else
      begin
        while (glowa^.nastepny<>nil) and (glowa^.nastepny^.tytul<tytul) do glowa:=glowa^.nastepny;
        tmp^.nastepny:=glowa^.nastepny;
        glowa^.nastepny:=tmp;
        tmp^.poprzedni:=glowa;
        glowa:=tmp;
      end;
  while (glowa^.nastepny<>nil) do glowa:=glowa^.nastepny;
  glowa^.nastepny:=nil;
  while (glowa^.poprzedni<>nil) do glowa:=glowa^.poprzedni;
  glowa^.poprzedni:=nil;
  tmp:=nil;
  end;

  procedure dodaj_ksiazke_do_uzytkownika (var glowa : wsk_ksiazka; var el : wsk_ksiazka); //dodanie ksiazki do listy wypozyczonych
  var
    tmp : wsk_ksiazka;
  begin
    if (glowa = nil) then
      begin
        new(glowa);
        glowa^:=el^;
        glowa^.poprzedni:=nil;
        glowa^.nastepny:=nil;
        glowa^.wsk_na_org:=el;
      end
    else
      if glowa^.tytul>el^.tytul then
        begin
          new(tmp);
          tmp^:=el^;
          tmp^.nastepny:=glowa;
          tmp^.poprzedni:=glowa^.poprzedni;
          glowa^.poprzedni:=tmp;
          tmp^.wsk_na_org:=el;
        end
      else
        begin
          while (glowa^.nastepny<>nil) and (el^.tytul>glowa^.tytul) do glowa:=glowa^.nastepny;
          new(tmp);
          tmp^:=el^;
          tmp^.poprzedni:=glowa;
          tmp^.wsk_na_org:=el;
          if glowa^.nastepny<> nil then glowa^.nastepny^.poprzedni:=tmp;
          tmp^.poprzedni:=glowa;
          tmp^.nastepny:=glowa^.nastepny;
          glowa^.nastepny:=tmp;
          glowa:=tmp;
        end;
  while (glowa^.nastepny<>nil) do glowa:=glowa^.nastepny;
  glowa^.nastepny:=nil;
  if glowa^.poprzedni<>nil then
  while glowa^.poprzedni<>nil do glowa:=glowa^.poprzedni;
  tmp:=nil
  end;

begin
  if (opcja=0) then dodaj_ksiazke_do_biblioteki (glowa)
  else dodaj_ksiazke_do_uzytkownika (glowa,el);
end;

procedure zapisz_do_plikow(glowa_uzytkownicy : wsk_uzytkownik; glowa_ksiazki : wsk_ksiazka);
{Procedura zapisuje informacje o ksiazkach i uzytkownikach do poszczegolnych plikow.
Wywoalana z wskaznikami wyslanymi przez wartosc na poczatek listy uzytkownikow i ksiazek}

    function blad_pliku_zapis (var plik : text; nazwa : string) : boolean;
    {Sprawdzenie czy nie nastapil plik otwarcia do zapisu. Zwraca false jezeli nie bylo
    zadnego bledu}
    begin
    {$I-}
    rewrite(plik);//otwarcie do zapisu pliku z poszczegolnymi danymi
    {$I+}
    if IOresult <> 0 then //jesli blad zmiany folderu
     begin
       clrscr;
       gotoxy(2,2);
       writeln(' Blad przy zapisywaniu rekordu do ',nazwa);
       gotoxy(2,3);
       writeln(' Rekord nie zostanie zapisany...');
       gotoxy(2,4);
       writeln(' Upewnij sie, ze nie uzyles niedozwolonych znakow...');
       gotoxy(2,5);
       writeln(' Nacisnij [ENTER]');
       readln;
       blad_pliku_zapis:=true;
     end
   else blad_pliku_zapis:=false;
    end;

    procedure zapisz_uzytkownikow (glowa_uzytkownicy : wsk_uzytkownik; var glowa_ksiazki : wsk_ksiazka);
    {Procedura zapisujaca uzytkownikow i dane o nich oraz informacje o przypisanych im ksiazkach
    do poszczegolnych plikow. Wywolywana z parametrem wyslanym przez wartosc jako wskaznik na
    poczatek listy ksiazek.}

        procedure zapis_danych_uzytkownika( glowa_uzytkownicy : wsk_uzytkownik );
        var
          adres : string;
          puzytkownik : text;
          tmp : wsk_ksiazka;
        begin
          sprawdz_folder('uzytkownicy');
          adres:=concat(glowa_uzytkownicy^.nazwisko,'_',glowa_uzytkownicy^.imie,'.txt'); //tworzenie nazwy pliku dla danych dla uzytkownika
          assign(puzytkownik,adres); //przypisanie pliku szczegolowego
          if not blad_pliku_zapis(puzytkownik,adres) then
            begin
              writeln(puzytkownik,glowa_uzytkownicy^.nazwisko);
              writeln(puzytkownik,glowa_uzytkownicy^.imie);
              writeln(puzytkownik,glowa_uzytkownicy^.pesel);
              writeln(puzytkownik,glowa_uzytkownicy^.ilosc_wypozyczonych_ksiazek);
              tmp:=nil;
              while (glowa_uzytkownicy^.glowa_ksiazek<>nil) do //jesli jakies ksiazki sa ypozyczone przez uzytkownika
                begin
                  writeln(puzytkownik,glowa_uzytkownicy^.glowa_ksiazek^.autor); //zapis do pliku kolejnych informacji o kazdej ksiazce
                  writeln(puzytkownik,glowa_uzytkownicy^.glowa_ksiazek^.tytul);
                  writeln(puzytkownik,glowa_uzytkownicy^.glowa_ksiazek^.wydawnictwo);
                  writeln(puzytkownik,glowa_uzytkownicy^.glowa_ksiazek^.rok_miejsce_wydania);
                  writeln(puzytkownik,glowa_uzytkownicy^.glowa_ksiazek^.dostepnosc);
                  tmp:=glowa_uzytkownicy^.glowa_ksiazek; //zapamietanie aktualnego wskaznika
                  glowa_uzytkownicy^.glowa_ksiazek:=glowa_uzytkownicy^.glowa_ksiazek^.nastepny;
                end;
              if tmp<>nil then
              while tmp^.poprzedni<>nil do
                tmp:=tmp^.poprzedni;
              glowa_uzytkownicy^.glowa_ksiazek:=tmp; //przypisanie pierwszego
              close(puzytkownik); //zamkniecie pliku z szczegolwymi danymi
            end
          else usun_ksiazki_uzytkownika(glowa_ksiazki,glowa_uzytkownicy^.glowa_ksiazek,1);
          chdir('..');  //cofniecie do nadrzednego folderu
      end;
    var
      uzytkownicy : text;
    begin
      assign(uzytkownicy,'lista_uzytkownicy.txt');//otwrcie pliku z lista uzytkownikow
      rewrite(uzytkownicy);
      while (glowa_uzytkownicy<>nil) do //dopki kolejny uzytkownik istnieje
        begin
           writeln(uzytkownicy,glowa_uzytkownicy^.nazwisko); //zapisanie do listy uzytkownika
           writeln(uzytkownicy,glowa_uzytkownicy^.imie);
           if glowa_uzytkownicy^.nazwisko='' then glowa_uzytkownicy^.nazwisko:=' ';
           if glowa_uzytkownicy^.imie='' then glowa_uzytkownicy^.imie:=' ';
           zapis_danych_uzytkownika(glowa_uzytkownicy);
           glowa_uzytkownicy:=glowa_uzytkownicy^.nastepny; //przejscie do nastepnego elementu
        end;
      close(uzytkownicy); //zamkniecie pliku z lista uzytkownikow
    end;

    procedure zapisz_ksiazki (glowa_ksiazki : wsk_ksiazka);
    {Procedura zapisujaca ksiazki i dane o nich do poszczegolnych plikow. Wywolywana z parametrem
    wyslanym przez wartosc jako wskaznik na poczatek listy ksiazek}
    var
      adres : string;
      pksiazka, ksiazki : text;
    begin
      assign(ksiazki,'lista_ksiazki.txt'); //przypisanie pliku z lista ksiazek
      rewrite(ksiazki); //otwarcie do zapisu
      while (glowa_ksiazki<>nil) do //dopoki koniec listy
        begin
          writeln(ksiazki,glowa_ksiazki^.tytul);
          sprawdz_folder('ksiazki');
          if glowa_ksiazki^.tytul='' then
            glowa_ksiazki^.tytul:=' ';
          adres:=concat(glowa_ksiazki^.tytul,'.txt');
          assign(pksiazka,adres);
          if not blad_pliku_zapis(pksiazka,adres) then
            begin
              writeln(pksiazka,glowa_ksiazki^.tytul);
              writeln(pksiazka,glowa_ksiazki^.autor);
              writeln(pksiazka,glowa_ksiazki^.wydawnictwo);
              writeln(pksiazka,glowa_ksiazki^.rok_miejsce_wydania);
              writeln(pksiazka,glowa_ksiazki^.dostepnosc);
              close(pksiazka);//zamkneicie pliku
            end;
          chdir('..'); //cofniecie do folderu nadrzednego
          glowa_ksiazki:=glowa_ksiazki^.nastepny;  //przejsice do nastepnego elemnetu
        end;
      close(ksiazki);//zamkniecie pliku z lista ksiazek
    end;

begin
  zapisz_uzytkownikow (glowa_uzytkownicy,glowa_ksiazki); //przejscie do zapisu do pliku uzytkownikow
  zapisz_ksiazki (glowa_ksiazki); //przejscie do zapisu do pliku ksiazek
  clrscr;
  gotoxy(2,2);
  write('Zapisano zmiany...!');
  delay(1000);
end;

procedure wyswietl(var g_ksiazki : wsk_ksiazka; var g_uzytkownicy : wsk_uzytkownik; var znak : char);
  {Menu wyswietlania ksiazek/uzytkownikow, jako parametry przyjmuje wskazniki do poszczególnych
  poczatkow list}

  procedure pisz_menu_wyswietlania_list(var opcja : byte);
  {Procedura wyswietlajaca menu. Wywolywana z parametrem wyslana przez zmienna, w celu
  resetowania wybranej opcji, gdy ponownie wraca sie so menu}
  begin
    clrscr;
    gotoxy(2,2);
    write('1. Wyswietlanie uzytkownikow');
    gotoxy(2,3);
    write('2. Wyswietlanie ksiazek');
    gotoxy(1,2);
    write('>');
    gotoxy(windmaxx-length('Backspace - powrot'),windmaxy-2);
    write('Backspace - powrot');
    gotoxy(1,2);
    znak:=#0;
    opcja:=1; //zerowanie opcji do pierwszego wyboru z listy
  end;

  procedure wybor_opcji_menu (var opcja : byte; var g_ksiazki : wsk_ksiazka; var g_uzytkownicy : wsk_uzytkownik; var znak : char);
  {Procedura wyboru opcji w menu wyswietlania. Wywolana z parametrami wysalnymi przez zmienna: opcje informujaca o
  aktualnym rodzaju edycj (ksiazka/uzytkownik), wskaznik na glowe listy ksiazek w bibliotece oraz wskaznik na glowe
  listy uzytkownikow}
  var
    tmp : wsk_ksiazka;
  begin
    tmp:=nil;
    case opcja of //zaleznie od opcji
      1 : begin
            wyswietl_uzytkownikow(g_uzytkownicy,g_ksiazki,znak); //przejscie do wywietlania i edytowania danych uzytkownikow
            sortuj_uzytkownikow (g_uzytkownicy);//sortowanie w razie zmienionych danych
            //zapisz_do_plikow(g_uzytkownicy, g_ksiazki);//zapisanie zmian
      end;
      2 : begin
            wyswietl_ksiazki(g_ksiazki,0,0,tmp,znak);
            sortuj_ksiazki (g_ksiazki); //sortowanie w razie zmienionych danych
            //zapisz_do_plikow(g_uzytkownicy, g_ksiazki);//zapisanie zmian
      end;
    end;
  end;

var
  opcja: byte;//zmienna pomocnicza do okreslenia wyboru opcji z tego menu (przyslania globalna zmienna)
begin
  pisz_menu_wyswietlania_list(opcja);//wyswietlanie menu wyswietlania
  while (znak<>#8) do //petla do nacisniecia klawisza powrotu ' backspace'
    begin
      znak:=readkey;
      case znak of
        #72 : begin
                if (wherey<>2) then
                  begin
                    write(' ');
                    gotoxy(wherex-1,wherey-1);
                    write('>');
                    gotoxy(wherex-1,wherey);
                    dec(opcja);
                  end;
        end;
        #80 : begin
                if (wherey<>3) then
                  begin
                    write(' ');
                    gotoxy(wherex-1,wherey+1);
                    write('>');
                    gotoxy(wherex-1,wherey);
                    inc(opcja);
                  end;
        end;
        #13 : begin
                wybor_opcji_menu (opcja, g_ksiazki, g_uzytkownicy,znak); //wybor dzialania
                if znak=#27 then break;
                pisz_menu_wyswietlania_list(opcja);//ponowne wyswietlenie menu
        end;
        #27 : break;
      end;
    end;
  //zapisz_do_plikow(g_uzytkownicy, g_ksiazki); //zapisz do plikow zmiany
end;

procedure wyswietl_ksiazki(var glowa : wsk_ksiazka; opcja, opcja2 : byte; var lista_ksiazek_uzytkownika : wsk_ksiazka; var znak : char);
{procedura odpowiedzialna za menu wyswietlenia i edcyji ksiazek. Wywolana z parametrami wyslanymi przez zmienna:
wskaznika na poczatek listy ksiazek, opcjami sterujacymi dzialaniem procedury oraz wskaznikiem na poczatek listy ksiazek
biblioteki. Ostatni parametr jest wysylamy jako nil gdy nie zajmujemy sie uzytownikiem}
      procedure edycja_ksiazki (var element: wsk_ksiazka; opcja : byte; var lista_ksiazek_uzytkownika : wsk_ksiazka; var z : char);
      {Procedura edycji ksiazki. Umozliwia zmiane poszczegolnych danych oraz usuniecie ksiazki z (bilioteki/listy wypozyczonych ksiazek).
      Wywolana z parametrami wysalnymi przez zmienna: wskaznika na wybrany element, opcja sterujaca dzialaniem procedury
      oraz wskaznikiem na glowe listy ksiazek biblioteki}
          procedure edytuj_dane_ksiazki (var element : wsk_ksiazka; var znak : char);
          {Procedura edycji danych ksiazki. Wywolana z zmienna wskaznikowa na
          wybrany element}
              procedure tytul(var element : wsk_ksiazka);
              {Procedura edycji tytulu. Wywolana przez zmienna wskaznikowa
              na wybrany element}
              var
                tytul : pole;
              begin
                clrscr;
                gotoxy(2,2);
                write('Podaj nowy tytul:');
                gotoxy(2,3);
                readln(tytul);
                tytul:=upcase(tytul);//zamiana liter na duze
                element^.tytul:=tytul;
              end;

              procedure autor(var element : wsk_ksiazka);
              {Procedura edycji autora. Wywolana przez zmienna wskaznikowa
              na wybrany element}
              var
                autor : pole;
              begin
                clrscr;
                gotoxy(2,2);
                write('Podaj nowego autora:');
                gotoxy(2,3);
                readln(autor);
                autor:=upcase(autor);//zamiana liter na duze
                element^.autor:=autor;
              end;

              procedure wydawnictwo(var element : wsk_ksiazka);
              {Procedura edycji wydawnictwa. Wywolana przez zmienna wskaznikowa
              na wybrany element}
              var
                wydawnictwo : pole;
              begin
                clrscr;
                gotoxy(2,2);
                write('Podaj nowe wydawnictwo:');
                gotoxy(2,3);
                readln(wydawnictwo);
                wydawnictwo:=upcase(wydawnictwo);
                element^.wydawnictwo:=wydawnictwo;
              end;

              procedure rok_miejsce_wydania(var element : wsk_ksiazka);
              {Procedura edycji roku wydania. Wywolana przez zmienna wskaznikowa
              na wybrany element}
              var
               rok_miejsce_wydania : pole;
              begin
                clrscr;
                gotoxy(2,2);
                write('Podaj nowe rok i miejsce wydania:');
                gotoxy(2,3);
                readln(rok_miejsce_wydania);
                element^.rok_miejsce_wydania:=rok_miejsce_wydania;
              end;

              procedure wypisz_element_na_ekran(element : wsk_ksiazka);
              {Procedura wypisania edytowanego elementu. Wywolana przez zmienna wskaznikowa
              na wybrany element przez wartosc}
              begin
                clrscr;
                gotoxy(2,2);
                write('"',element^.tytul,'"');
                gotoxy(2,3);
                write(element^.autor);
                gotoxy(2,4);
                write(element^.wydawnictwo);
                gotoxy(2,5);
                write(element^.rok_miejsce_wydania);
                gotoxy(2,6);
                write('Dostepnosc: ');
                if element^.dostepnosc=1 then write('dostepna')
                else write('brak');
              end;

              procedure dostepnosc(element : wsk_ksiazka);
              {Procedura przywracania dostepnosci. Wywolana przez zmienna wskaznikowa
              na wybrany element przez wartosc}
              begin
                element^.dostepnosc:=1;
              end;

          begin
            repeat
              wypisz_element_na_ekran(element); //wypisz dane elementu
              gotoxy(windmaxx-odleglosc_od_prawej_krawedzi  ,2);
              write('Co chcesz edytowac?');
              gotoxy(windmaxx-odleglosc_od_prawej_krawedzi  ,3);
              write('T - tytul');
              gotoxy(windmaxx-odleglosc_od_prawej_krawedzi  ,4);
              write('A - autor');
              gotoxy(windmaxx-odleglosc_od_prawej_krawedzi  ,5);
              write('R - rok i miejsce wydania');
              gotoxy(windmaxx-odleglosc_od_prawej_krawedzi  ,6);
              write('W - wydawnictwo');
              gotoxy(windmaxx-odleglosc_od_prawej_krawedzi  ,7);
              if element^.dostepnosc=0 then write('D - przywroc dostepnosc');
              gotoxy(windmaxx-length('Backspace - powrot'),windmaxy-2);
              write('Backspace - powrot');
              repeat
                znak:=readkey;
              until ((znak=#27) or (znak='d') or (znak='D') or (znak='a') or (znak='A') or (znak='T') or (znak='t') or (znak='w') or (znak='W') or (znak='r') or (znak='R') or (znak=#8));
              if znak<>#8 then
                if (znak='t') or (znak='T') then tytul(element);
                if (znak='a') or (znak='A') then autor(element);
                if (znak='w') or (znak='W') then wydawnictwo(element);
                if (znak='r') or (znak='R') then rok_miejsce_wydania(element);
                if element^.dostepnosc=0 then dostepnosc(element);
                if znak=#27 then break;
            until (znak=#8) ;
          end;

          procedure wypisz_element_na_ekran(element : wsk_ksiazka; opcja : byte);
          {Procedura wypisuje na ekran dane ksiazki. Wywolywana jest przez parametry wyslane
          przez wartosc: wskaznik na wybrany element oraz okreslenie czy ksiazka jest
          przetwarzana w menu ksiazki(opcja=0) czy w menu uzytkownika (opcja=0)}
          begin
            clrscr;
            gotoxy(2,2);
            write('"',element^.tytul,'"');
            gotoxy(2,3);
            write(element^.autor);
            gotoxy(2,4);
            write(element^.wydawnictwo);
            gotoxy(2,5);
            write(element^.rok_miejsce_wydania);
            gotoxy(2,6);
            if opcja=0 then //jesli aktualnie wybrane menu ksiazki
              begin
                write('Dostepnosc: ');
                if element^.dostepnosc=1 then write('dostepna') //jesli ksiazka nie jest wypozyczona
                else write('brak');
              end;
            gotoxy(windmaxx-length('Backspace - powrot'),windmaxy-2);
            write('Backspace - powrot');
          end;

      begin
        repeat
          repeat
            wypisz_element_na_ekran(element, opcja); //wypisz dane aktualnie wybranego elementu ekran
            if opcja=0 then
              begin
                gotoxy(windmaxx-odleglosc_od_prawej_krawedzi  ,2);
                write('E - Edycja');
                gotoxy(windmaxx-odleglosc_od_prawej_krawedzi  ,3);
                write('U - Usun');
              end
            else
              begin
                gotoxy(windmaxx-odleglosc_od_prawej_krawedzi  ,2);
                write('U - Usun z listy wypozyczonych');
              end;
            z:=readkey;
          until ((z=#27) or (z='e') or (z='E') or (z='U') or (z='u') or (z=#8));
          if z<>#8 then
            if opcja=0 then //jesli edycja ksiazki w bibliotece
              if (z='E') or (z='e') then
                edytuj_dane_ksiazki(element,z); //edycja danych ksiazki
            if (z='u') or (z='U') then //jesli wybrano usuwanie
              begin
               if opcja = 1 then
                 usun_ksiazke(element,1) //jesli edycja uzytkownika, to usun z listy wypoczyczonych
               else usun_ksiazke(element,0); // usun ksiazke z biblioteki
               break;
              end;
            if z=#27 then break;
        until (z=#8);
      end;

      procedure wyswietl_liste(var glowa : wsk_ksiazka;i : integer; opcja, opcja2 : byte; var p : boolean);
      {Procedura wysietla poczatkowa liste uzytkownikow. Jako parametry przez wartosc przyjumje wskaznik
      na pierwszy element list uzytkownikow oraz liczbe elementow listy. Jako parametr przez zmienna przyjmuje
      zmienna logiczna dla okreslenia czy lista istnieje.}
      var
         dlugosc : integer; //zmienna przechowujaca ilosc elementow listy
         tmp : wsk_ksiazka;
      begin
          clrscr;
          dlugosc:=i;
          i:=0;
          p:=false;
          tmp:=nil;
          if (glowa=nil) then //jesli list anie istnieje
            begin
              brak_danych;
              p:=true; //zachowana informacja, ze lista nie istnieje
            end
          else
            while ((i<dlugosc) and (2+i<windmaxy-odleglosc_od_dolnej_krawedzi+1) and (wherey<>windmax-odleglosc_od_dolnej_krawedzi+1)) do //powtarzaj jesli daalsze elementy istnije i zmieszcza sie na ekranie
              begin
                gotoxy(1,1);
                write('Lista ksiazek: ');
                gotoxy(2,2+i);
                if opcja=1 then //jesli procedura wywolana z poziomu uzytkownika
                  if opcja2=1 then //jesli wyswietlanie wypozyczonych ksiazek
                    if glowa^.wsk_na_org^.dostepnosc=1 then
                      begin
                        usun_ksiazke(glowa,1); //jesli ksiazka jest dostepna to usun z listy wypozyczonych u uzytkownika
                        dec(dlugosc);
                      end;
                if glowa<>nil then //jesli aktualna glowa istnieje
                  begin
                    if glowa^.tytul<>'' then
                      begin
                        if length(glowa^.tytul)>20 then
                          write('"',glowa^.tytul[1..20],'..", ',glowa^.autor)
                        else
                          write('"',glowa^.tytul,'", ',glowa^.autor);
                      if glowa^.dostepnosc = 1 then
                        if (opcja2=0) or (opcja=0) then
                          write(' - dostepna'); //jesli menu wyswietlania ksiazek
                      tmp:=glowa;
                      glowa:=glowa^.nastepny;
                      end;
                  end;
                inc(i);
              end;
          glowa:=tmp;
          if glowa<>nil then
            while glowa^.poprzedni<>nil do glowa:=glowa^.poprzedni;
          tmp:=nil;
        end;

      procedure ruch_w_gore_ksiazki (var aktualnie_wybrane : wsk_ksiazka; var z : integer);
      {Procedura odpowiedzialna za ruch w gore na liscie ksiazek. Wywolana z parametrani wyslanymi
      przez zmienna: wksaznik na aktulnie wybrany elemnent oraz nr wiersza pozycji graficznego wskaznika}

          procedure koniec_ekranu( var aktualnie_wybrane : wsk_ksiazka);
          var
            tmp : wsk_ksiazka;
          begin
            tmp:=aktualnie_wybrane; //zapmaietanie adresu elementu
            z:=2;
            clrscr;
            while (z<windmaxy-odleglosc_od_dolnej_krawedzi) and (tmp^.nastepny<>nil) do //wypisanie kolejnych ekranow az do dolnej granicy ekranu
              begin
                gotoxy(1,1);
                write('Lista ksiazek: ');
                gotoxy(2,z);
                write('"',tmp^.tytul[1..30],'", ', tmp^.autor);
                if tmp^.dostepnosc = 1 then write(' - dostepna'); //dopisz informacje o dostepnosci
                tmp:=tmp^.nastepny;
                inc(z);
              end;
            gotoxy(windmaxx-length('Backspace - powrot'),windmaxy-2);
            write('Backspace - powrot');
            gotoxy(2,2);
            write('"',aktualnie_wybrane^.tytul[1..30],'", ', aktualnie_wybrane^.autor);
            if aktualnie_wybrane^.dostepnosc = 1 then write(' - dostepna'); //dopisz informacje o dostepnosci
            gotoxy(1,2);
            write(' ');
            gotoxy(1,2);
            write('>');
            gotoxy(1,2);
          end;

       begin
        if (aktualnie_wybrane^.poprzedni<>nil) then //jesli porzedni element istnieje
          begin
            if (wherey=2) then //jesli osiagnieto gorna granice okna
              begin
                aktualnie_wybrane:=aktualnie_wybrane^.poprzedni;
                koniec_ekranu(aktualnie_wybrane);
              end
            else
              begin
                write(' ');
                gotoxy(wherex-1,wherey-1);
                write('>');
                gotoxy(wherex-1,wherey);
                dec(z);
                aktualnie_wybrane:=aktualnie_wybrane^.poprzedni;
              end;
         end;
      end;

      procedure ruch_w_dol_ksiazki (var aktualnie_wybrane: wsk_ksiazka; var z : integer);
      {Procedura odpowiedzialna za ruch w dol na liscie ksiazek. Wywolana z parametrani wyslanymi
      przez zmienna: wksaznik na aktulnie wybrany elemnent oraz nr wiersza pozycji graficznego wskaznika}

          procedure koniec_ekranu( var aktualnie_wybrane : wsk_ksiazka);
          var
            tmp : wsk_ksiazka; //pomcnicza zmienna wskaznikowa
          begin
            tmp:=aktualnie_wybrane;//zapamietanie aktuaalnie wybranego elementu
                z:=wherey;
                clrscr;
                while (z>2) and (tmp^.poprzedni<>nil) do //wypisz poprzednie elementy az do gornej krawedzi ekranu
                  begin
                    gotoxy(1,1);
                    write('Lista ksiazek: ');
                    gotoxy(2,z-1);
                    write('"',tmp^.poprzedni^.tytul[1..30],'", ', tmp^.poprzedni^.autor);
                    if tmp^.dostepnosc = 1 then write(' - dostepna'); //dopisz informacje o dosepnosci
                    tmp:=tmp^.poprzedni;
                    dec(z);
                  end;
                gotoxy(windmaxx-length('Backspace - powrot'),windmaxy-2);
                write('Backspace - powrot');
                gotoxy(2,windmaxy-odleglosc_od_dolnej_krawedzi);
                write(aktualnie_wybrane^.tytul,', ', aktualnie_wybrane^.autor );
                if aktualnie_wybrane^.dostepnosc = 1 then write(' - dostepna');//dopisz informacje o dosepnosci
                gotoxy(1,windmaxy-odleglosc_od_dolnej_krawedzi);
                write(' ');
                gotoxy(1,windmaxy-odleglosc_od_dolnej_krawedzi);
                write('>');
                gotoxy(1,windmaxy-odleglosc_od_dolnej_krawedzi);
          end;

      begin
        if (aktualnie_wybrane^.nastepny<>nil) then //jesli nastepny element istnieje
          begin
            if (wherey=windmaxy-odleglosc_od_dolnej_krawedzi) then //jesli osiagnieto dolno granice ekranu
              begin
                aktualnie_wybrane:=aktualnie_wybrane^.nastepny;
                koniec_ekranu(aktualnie_wybrane);
              end
            else //jesli mozna przesunac sie w dol bez komplikacji
              begin
                write(' ');
                gotoxy(wherex-1,wherey+1);
                write('>');
                gotoxy(wherex-1,wherey);
                inc(z);
                aktualnie_wybrane:=aktualnie_wybrane^.nastepny;
              end;
          end;
      end;

      procedure wybor_ksiazki (var aktualnie_wybrane, lista_ksiazek_uzytkownika : wsk_ksiazka; var opcja, opcja2 : byte; var znak : char);
      {Wykonuje dzialanie wybrania ksiazki z listy na podstawie przeslancyh parametrow sterujacych.
      Jako parametry wywolania przyjmuje wyslane przez zmienna: wskaznik na aktualnie wybranego uzytkownika,
      adres na poczatek listy ksiazek, opcja i opcja2 sterujace przeznaczeniem procedury oraz zmienna znakowa
      ktora steruje programem po wyjsciu z procedury}
            begin
        if opcja=1 then //jesli edycja z poziomu uzytkownika
          begin
            if aktualnie_wybrane^.dostepnosc=1 then //jesli ksiazka jest dostepna
              begin
                aktualnie_wybrane^.dostepnosc:=0;
                dodaj_ksiazke(lista_ksiazek_uzytkownika,1,aktualnie_wybrane);
                sortuj_ksiazki(lista_ksiazek_uzytkownika);
                sortuj_ksiazki(aktualnie_wybrane);
              end
            else
              begin
                if opcja2=1 then //jesli ksiazka jest niedostepna i aktualnie edycja z poziomu wypozyczonych ksiazek
                  begin
                    edycja_ksiazki(aktualnie_wybrane,1,lista_ksiazek_uzytkownika,znak);
                    if aktualnie_wybrane<>nil then
                      while aktualnie_wybrane^.poprzedni<>nil do aktualnie_wybrane:=aktualnie_wybrane^.poprzedni;
                    lista_ksiazek_uzytkownika:=aktualnie_wybrane;
                    sortuj_ksiazki(lista_ksiazek_uzytkownika);
                  end
                else znak:=#2;//jesli z poziomu dodawania ksiazki
              end;
          end
        else //jesli edycja z poziomu biblioteki
          begin
            edycja_ksiazki(aktualnie_wybrane,0,lista_ksiazek_uzytkownika,znak);
            if aktualnie_wybrane = nil then lista_ksiazek_uzytkownika:=nil;
            while aktualnie_wybrane^.poprzedni<>nil do aktualnie_wybrane:=aktualnie_wybrane^.poprzedni;
            sortuj_ksiazki(aktualnie_wybrane);
            if znak<>#27 then znak:=#0;
          end;

      end;

      procedure info_o_aktualnej_opcji (opcja, opcja2 : byte; z : integer);
      {Procedura informujaca o aktualnym dzialaniu u gory ekranu. Przyjmuje jako
      parametry przez wartosc: z-informuje o aktualnym polozeniu graficznego wskaznika,
      dla opcja=0 dla wysietlania ksiazek z biblioteki, opcja=1 dla wyswietlania
      dzialan zwiazanych z uzytkownikiem, opcja2=1 jesli wyswietlamy aktualne ksiazki
      wypozyczone przez uzytkownika, opcja2=0 jesli dodajemy ksiazki uzytkownikowi}
      begin
        if opcja=0 then
            begin
              gotoxy(1,1);
              write('Lista ksiazek w Bibliotece: ');
            end
        else
          begin
            gotoxy(1,1);
            if opcja2=1 then write('Ksiazki wypozyczone przez uzytkownika: ')
            else write ('Wybierz ksiazki dla uzytkownika: ');
          end;
        gotoxy(1,z);
      end;

var
  aktualnie_wybrane : wsk_ksiazka; //pomocnicze zmienne wskaznikowe
  i, z : integer;
  istnienie : boolean;
begin
  i:=licz_ile_ksiazek(glowa);
  wyswietl_liste(glowa,i,opcja,opcja2,istnienie);
  gotoxy(windmaxx-length('Backspace - powrot'),windmaxy-2);
  write('Backspace - powrot');
  if istnienie=false then
    begin
      gotoxy(1,2);//pocztakowe ustawienie wskaznika
      write('>');
      aktualnie_wybrane:=glowa;
      gotoxy(1,2);
      z:=2;
      info_o_aktualnej_opcji (opcja,opcja2,z);
      while (znak<>#8) do
        begin
           //wysietlanie informacji na gorze ekranu
          znak:=readkey;
          case znak of
            #72 : ruch_w_gore_ksiazki(aktualnie_wybrane,z); //jesli strzalka w gore
            #80 : ruch_w_dol_ksiazki (aktualnie_wybrane,z); //jesli strzalka w dol
            #13 : begin
                    wybor_ksiazki(aktualnie_wybrane,lista_ksiazek_uzytkownika,opcja,opcja2,znak);
                    glowa:=aktualnie_wybrane;
                    if znak=#27 then break;
                    if znak=#1 then break;
                    if not (znak=#2) then
                      begin
                        wyswietl_ksiazki(glowa,opcja,opcja2,lista_ksiazek_uzytkownika,znak);
                        znak:=#8;
                      end;
            end;
            #27 : break;
          end;
        end;
    end;
end;

procedure wyswietl_uzytkownikow(var glowa : wsk_uzytkownik; var lista : wsk_ksiazka; var znak : char);
{Wyswietlanie uzytkownikow oraz ich edycja. Jako parametr wywolania przyjmuje wyslane przez zmienna
wskaznik na poczatek listy ksiazek w bibliotece. Zwraca wskaznik na glowe zeedytowanej listy
uzytkownikow listy uzytkownikow oraz }
      procedure edycja_uzytkownika (var element : wsk_uzytkownik; var lista_ksiazek : wsk_ksiazka; var znak: char);
      {Edycja danego uzytkownika. Jako parametry przyjmuje wskazniki wyslane przez zmienna na
      wybrany element oraz na glowe listy ksiazek}
          procedure wypisz_element_na_ekran (element : wsk_uzytkownik);
          //wypisanie danych uzytkownika
          begin
            clrscr;
            gotoxy(2,2);
            write(element^.nazwisko);
            gotoxy(2,3);
            write(element^.imie);
            gotoxy(2,4);
            write(element^.pesel);
          end;

          procedure usun_uzytkownika (var element : wsk_uzytkownik; var lista_ksiazek : wsk_ksiazka);
          {Procedura odpowiedzialna za usuniecie uzytkownika z biblioteki wraz z odblokowaniem
          ksiazek do niego przypisanych. Jako parametr przyjmuje wyslane przez zmienna wskazniki
          na wybrany element oraz adres na poczatek listy ksiazek}
          var
            tmp : wsk_uzytkownik;
          begin
            if (element^.nastepny<>nil) and (element^.poprzedni<>nil) then //jesli poprzedni i nastepny element istnieje
             begin
               tmp:=element;
               element^.poprzedni^.nastepny:=element^.nastepny;
               element^.nastepny^.poprzedni:=element^.poprzedni;
               element:=element^.poprzedni;
               while tmp^.glowa_ksiazek <> nil do usun_ksiazki_uzytkownika (lista_ksiazek, tmp^.glowa_ksiazek, 1);
               dispose(tmp);
             end
            else
             if (element^.nastepny<>nil) then //jesli nastepny element istnieje
               begin
                 tmp:=element;
                 element:=element^.nastepny;
                 element^.poprzedni:=nil;
                  while tmp^.glowa_ksiazek <> nil do usun_ksiazki_uzytkownika (lista_ksiazek, tmp^.glowa_ksiazek, 1);
                 dispose(tmp);
               end
             else
               if (element^.poprzedni<>nil) then //jeslipoprzedni element istnieje
                 begin
                   tmp:=element;
                   element:=element^.poprzedni;
                   element^.nastepny:=nil;
                   while tmp^.glowa_ksiazek <> nil do usun_ksiazki_uzytkownika (lista_ksiazek, tmp^.glowa_ksiazek, 1);
                   dispose(tmp);
                 end
                 else //jesli jest tylko jeden element
                   begin
                   tmp:=element;
                   usun_ksiazki_uzytkownika (lista_ksiazek, tmp^.glowa_ksiazek,1);
                   dispose(tmp);
                   element:=nil;
                   end;
             tmp:=nil;
          end;

          procedure wyswietl_wypozyczone_ksiazki (var element: wsk_uzytkownik; var znak : char);
          {Procedura wyswietla liste wypozyczonych ksiazek, jako parametr wejsciowy
          przyjmuje wskaznik na wybranego uzytkownika wyslany przez zmienna}
          begin
            if (element^.glowa_ksiazek=nil) then
                brak_danych
            else wyswietl_ksiazki(element^.glowa_ksiazek,1,1,element^.glowa_ksiazek,znak);
           {wywolanie procedury do wyswietlenia ksiazek przypisanych uzzytkownikowi
           z opcja=1 dla edycji zwiazanej z uzytkownikiem, opcja2=1 dla wyboru opcji
           wyswietlania ksiazek juz wypozyczonych i wskaznik dla dzialania procedury}
          end;

          function edytuj_dane_uzytkownika (element : wsk_uzytkownik; var znak : char) : wsk_uzytkownik;
          {Funkcja edytuje dane uzytkownika. Wywolana przeslanym przez wartosc wskaznika,
          Jako rezultat zwraca zedytowany element}
              procedure imie(var element : wsk_uzytkownik);
              //edycja imienia. Przekazanie uzytkownika przez zmienna wskaznikowa
              var
               imie : pole;
              begin
                clrscr;
                gotoxy(2,2);
                write('Podaj nowe imie:');
                gotoxy(2,3);
                readln(imie);
                imie:=upcase(imie);
                element^.imie:=imie;
              end;

              procedure nazwisko(var element : wsk_uzytkownik);
              //edycja nazwiska. Przekazanie uzytkownika przez zmienna wskaznikowa
              var
               nazwisko : pole;
              begin
                clrscr;
                gotoxy(2,2);
                write('Podaj nowe nazwisko:');
                gotoxy(2,3);
                readln(nazwisko);
                nazwisko:=upcase(nazwisko);
                element^.nazwisko:=nazwisko;
              end;

              procedure pesel(var element : wsk_uzytkownik);
              //edycja pesla. Przekazanie uzytkownika przez zmienna wskaznikowa
              var
               pesel : pole2;
              begin
                clrscr;
                gotoxy(2,2);
                write('Podaj nowy pesel:');
                gotoxy(2,3);
                readln(pesel);
                element^.pesel:=pesel;
              end;

              procedure wypisz_element_na_ekran(element : wsk_uzytkownik);
              //wypisanie informacji o uzytkowniku
              begin
                clrscr;
                gotoxy(2,2);
                write(element^.nazwisko);
                gotoxy(2,3);
                write(element^.imie);
                gotoxy(2,4);
                write(element^.pesel);
              end;

           begin
            repeat
              wypisz_element_na_ekran(element);//wypisz dane na ekran
              gotoxy(windmaxx-odleglosc_od_prawej_krawedzi  ,2);
              write('Co chcesz edytowac?');
              gotoxy(windmaxx-odleglosc_od_prawej_krawedzi  ,3);
              write('I - imie');
              gotoxy(windmaxx-odleglosc_od_prawej_krawedzi  ,4);
              write('N - nazwisko');
              gotoxy(windmaxx-odleglosc_od_prawej_krawedzi  ,5);
              write('P - pesel');
              gotoxy(windmaxx-length('Backspace - powrot'),windmaxy-2);
              write('Backspace - powrot');
              repeat
                znak:=readkey;//zczytuj klawisz, az nacisnieto jeden z odpowiednich
              until ((znak=#27) or (znak='i') or (znak='I') or (znak='n') or (znak='N') or (znak='p') or (znak='P') or (znak=#8));
              if znak<>#8 then
                if (znak='i') or (znak='I') then imie(element);
                if (znak='n') or (znak='N') then nazwisko(element);
                if (znak='p') or (znak='P') then pesel(element);
                if znak=#27 then break;
            until (znak=#8) ;
            edytuj_dane_uzytkownika:=element;//zedytowny element jako wartosc funkcji
           end;

          procedure pisz_menu_edycji_uzytkownika; //wypisanie menu edycji uzytkownika
          begin
            wypisz_element_na_ekran(element);
            gotoxy(windmaxx-odleglosc_od_prawej_krawedzi  ,2);
            write('E - edycja');
            gotoxy(windmaxx-odleglosc_od_prawej_krawedzi  ,3);
            write('U - usun');
            gotoxy(windmaxx-odleglosc_od_prawej_krawedzi  ,4);
            write('W - wyswietl wypozyczone ksiazki');
            gotoxy(windmaxx-odleglosc_od_prawej_krawedzi  ,5);
            write('D - dodaj ksiazki do uzytkownika');
            gotoxy(windmaxx-length('Backspace - powrot'),windmaxy-2);
            write('Backspace - powrot');
          end;

      begin
      repeat
        repeat
          pisz_menu_edycji_uzytkownika;//wypisanie menu edycji na ekranie
          znak:=readkey;
        until ((znak=#27) or (znak='e') or (znak='E') or (znak='U') or (znak='u') or (znak='D') or (znak='d') or (znak='w') or (znak='W') or (znak=#8));
        if znak<>#8 then //jesli wcisniety klawisz nie jest klawiszem powrotu
          if (znak='E') or (znak='e') then element:=edytuj_dane_uzytkownika(element,znak);
          if (znak='w') or (znak='W') then wyswietl_wypozyczone_ksiazki(element,znak);
          if (znak='u') or (znak='U') then
            begin
             usun_uzytkownika(element, lista_ksiazek);
             break;
            end;
          if ((znak='d') or (znak='D')) then
            wyswietl_ksiazki(lista_ksiazek,1,0,element^.glowa_ksiazek,znak);
           //opcja=1 dla edycji uzytkownika, opcja2=0 menu dodawania ksiazek
          if znak=#27 then break;
      until (znak=#8);
      end;

      procedure wyswietl_liste(glowa : wsk_uzytkownik; i : integer; var p : boolean);
      {Procedura wysietla cala liste na ekranie. Jako parametry przez wartosc przyjmuje kolejno wskaznik na glowe listy uzytkownikow oraz ilosc elementow listy
      . Jako parametr przez zmienna informacje czy lista istnieje 'true' czy nie 'false'}
      var
       dlugosc : integer; //zmienan pomocnicza z liczba elementow listy
      begin
        clrscr;
        dlugosc:=i;
        i:=0;
        p:=false;
        if glowa=nil then //jesli lista nie istnieje
          begin
            brak_danych;
            p:=true;
          end
        else //jesli lista istnieje
          begin
            gotoxy(1,1);
            write('Lista uzytkownikow: ');
            while ((i<dlugosc) and (2+i<windmaxy-odleglosc_od_dolnej_krawedzi+1) and (wherey<>windmax-odleglosc_od_dolnej_krawedzi+1) and (glowa<>nil)) do
            //powtarzaj dopoki nie wyswietlono wszystkch elementow, dopoki nie zajeto dostepnego obszaru oraz dopki aktualny element istnieje
              begin
                gotoxy(2,2+i);
                write(glowa^.nazwisko,' ', glowa^.imie,' ');//wypisz aktualny element na ekran
                glowa:=glowa^.nastepny;
                inc(i);
              end;
          end;
      end;

      procedure ruch_w_gore_uzytkownika (var aktualnie_wybrane : wsk_uzytkownik; var z : integer);
      {Procedura zmianny wskazania aktualnie wybranego uzytkownika na poprzedni w funkcji 'wysywietl_uzytkownikow',
      jako parametry przyjmuje wskaznik na aktualnie wybrany element listy uzytkownikow oraz licznik wiersza ekranu}

          procedure koniec_ekranu (var aktualnie_wybrane : wsk_uzytkownik);
          var
            tmp : wsk_uzytkownik;//pomocnicza zmienna wskaznikowa
            z : byte;
          begin
            tmp:=aktualnie_wybrane; //zapamietanie aktua
            z:=2; //zapamietanie polozenia graficznego wskaznika
            clrscr; //czyszczenie ekranu
            while (z<windmaxy-odleglosc_od_dolnej_krawedzi) and (tmp^.nastepny<>nil) do //dopoki nastepny element istnieje i zmienna 'z' nie wskazuje na dolna granice ekranu
              begin
                gotoxy(1,1);
                write('Lista uzytkownikow: ');
                gotoxy(2,z);
                write(tmp^.nastepny^.nazwisko,' ', tmp^.nastepny^.imie);
                tmp:=tmp^.nastepny;
                inc(z);
              end;
            gotoxy(windmaxx-length('Backspace - powrot'),windmaxy-2);//wypisanie info o mozliwosc i powrotu do wczesniejszego menu
            write('Backspace - powrot');
            gotoxy(2,2);
            write(aktualnie_wybrane^.nazwisko,' ', aktualnie_wybrane^.imie);//wypisanie elementu na ekran
            gotoxy(1,2);
            write(' ');//zmiana polozenia graficznego wskaznika
            gotoxy(1,2);
            write('>');
            gotoxy(1,2);
          end;

      begin
        if (aktualnie_wybrane^.poprzedni<>nil) then //jesli poprzedin element istnieje
          begin
            if (wherey=2) then //jesli graficzny wskaznik jest przy gornej granicy ekranu
              begin
                aktualnie_wybrane:=aktualnie_wybrane^.poprzedni; //przesuniecie wskaznika na poprzedni element
                koniec_ekranu(aktualnie_wybrane);
              end
            else
              begin
                write(' ');//zmiana polozenia graficznego wskaznika
                gotoxy(wherex-1,wherey-1);
                write('>');
                gotoxy(wherex-1,wherey);
                dec(z);
                aktualnie_wybrane:=aktualnie_wybrane^.poprzedni; //przesuniecie wskaznika na poprzedni element
              end;
          end;
      end;

      procedure ruch_w_dol_uzytkownika (var aktualnie_wybrane: wsk_uzytkownik; var z : integer);
      {Procedura zmianny wskazania aktualnie wybranego uzytkownika na nastepenego w funkcji 'wysywietl_uzytkownikow',
      jako parametry przyjmuje wskaznik na aktualnie wybrany element listy uzytkownikow oraz licznik wiersza ekranu}

          procedure koniec_ekranu ( var aktualnie_wybrane : wsk_uzytkownik);
          var
            tmp : wsk_uzytkownik; //pomocnicza zmienna wskaznikowa
            z : byte;
          begin
            tmp:=aktualnie_wybrane; //zapamietanie adresu na aktualny element
                z:=wherey; //zapamietaj polozenie graficznego wskaznika
                clrscr; //czysc ekran
                 while (z>2) and (tmp^.poprzedni<>nil) do //wypisanie elementow wczesniejszych az do gornej granicy ekranu
                  begin
                    gotoxy(1,1);
                    write('Lista uzytkownikow: ');
                    gotoxy(2,z-1);
                    write(tmp^.poprzedni^.nazwisko,' ', tmp^.poprzedni^.imie); //wypisz dwie informacje o uzytkowniku
                    tmp:=tmp^.poprzedni;
                    dec(z); //zmniejszenie odleglosci poloznia od gornej granicy ekranu
                  end;
                gotoxy(windmaxx-length('Backspace - powrot'),windmaxy-2); //wypiasanie informacji o mozliwosci pworotu do poprzedniego menu
                write('Backspace - powrot');
                gotoxy(2,windmaxy-odleglosc_od_dolnej_krawedzi);
                write(aktualnie_wybrane^.nazwisko,' ', aktualnie_wybrane^.imie);//wypisnie elementu na ekran
                gotoxy(1,windmaxy-odleglosc_od_dolnej_krawedzi);
                write(' ');
                gotoxy(1,windmaxy-odleglosc_od_dolnej_krawedzi);
                write('>');
                gotoxy(1,windmaxy-odleglosc_od_dolnej_krawedzi);
          end;

      begin
      if (aktualnie_wybrane^.nastepny<>nil) then //jesli nastepny element listy istnieje
        begin
        if (wherey=windmaxy-odleglosc_od_dolnej_krawedzi) then //jesli wskaznik na nie jest przy koncu okna
          begin
          aktualnie_wybrane:=aktualnie_wybrane^.nastepny; //przesuniecie wskaznika na nastepny element
          koniec_ekranu(aktualnie_wybrane);
          end
        else
          begin
          write(' ');
          gotoxy(wherex-1,wherey+1);
          write('>');
          gotoxy(wherex-1,wherey);
          inc(z);
          aktualnie_wybrane:=aktualnie_wybrane^.nastepny; //przesuniecie wskaznika na nastepny element
          end;
        end;
      end;

      procedure wybor_uzytkownika (var aktualnie_wybrane, glowa: wsk_uzytkownik; var glowa_ksiazek : wsk_ksiazka; var znak : char);
      {Procedura odpowiedzialna za dzialanie z aktualnie wybranym uytkownikiem. Jak parametry przyjumje kolejno adres aktualnie wybranego uzytkownika,
      adres glowy listy uzytkownikow, adres glowy listy ksiazek oraz znak dla sterowania programem po wyjsciu z procedury}
      begin
        edycja_uzytkownika(aktualnie_wybrane,glowa_ksiazek,znak); //przejscie do edycji aktualnie wybranego uzytkownika
        if aktualnie_wybrane<>nil then
          while aktualnie_wybrane^.poprzedni<>nil do
           aktualnie_wybrane:=aktualnie_wybrane^.poprzedni; //jesli aktualnie wskazywany element listy nei jest poczatkiem, przejdz do poczatku
        sortuj_uzytkownikow(aktualnie_wybrane); //sortowanie listy uzytkownikow
        if znak<>#27 then znak:=#8; //przypisanie do zmiennej 'znak' klawisza 'Backspace' w celu wyjscia z wszytkich wywolan funckcji wyswietl_uzytkownikow
      end;

var
  aktualnie_wybrane, tmp : wsk_uzytkownik; //pomocnicze zmienne wskaznikowe
  i,z : integer; //doadtkowe liczniki sterujace przy wyswietlaniu
  p: boolean; //zmienna logiczna z wartoscia true jesli lista istnieje
begin
  i:=licz_ile_uzytkownikow(glowa); //zliczanie elementow listy ksiazek
  wyswietl_liste(glowa,i,p); //wypisanie listy na ekran
  gotoxy(windmaxx-length('Backspace - powrot'),windmaxy-2);
  write('Backspace - powrot');
  z:=1;
  if p=false then
    begin
    gotoxy(1,2);
    write('>');
    aktualnie_wybrane:=glowa;
    gotoxy(1,2);
    tmp:=nil;
    while (znak<>#8) do //powtarzaj dopoki znak nie jest 'Backspace'
      begin
        znak:=readkey;
        case znak of
          #72 : ruch_w_gore_uzytkownika (aktualnie_wybrane,z); //jesli nacisnieto strzalke w gore
          #80 : ruch_w_dol_uzytkownika (aktualnie_wybrane,z); //jesli nacisnieto strzalke w dol
          #13 : begin
                   wybor_uzytkownika (aktualnie_wybrane,glowa,lista,znak); //jesli nacisnieto enter
                   glowa:=aktualnie_wybrane;
                   if znak=#27 then break;
                   if znak=#8 then znak:=#0;
                   wyswietl_uzytkownikow(glowa, lista, znak);
                   break;
          end;
          #27 : break; //jesli nacisnieto 'ESC'
        end;
      end;
    tmp:=nil;
    end;
end;

procedure dodaj (var g_ksiazki: wsk_ksiazka; var g_uzytkownicy : wsk_uzytkownik; var znak : char);
  {Wyswietla menu do dodawania danych, wypis tekstu poprzez procedure 'pisz'. Jako parametry
  przyjmuje glowy do ksiazek i uzytkownikow}
    procedure pisz_menu_dodawania(var opcja : byte); //Procedura odpowiedzialna za wypisanie menu dodawania
    begin
      clrscr;
      gotoxy(2,2);
      write('1. Dodaj uzytkownika');
      gotoxy(2,3);
      write('2. Dodaj ksiazke');
      gotoxy(1,2);
      write('>');
      gotoxy(windmaxx-length('Backspace - powrot'),windmaxy-2);
      write('Backspace - powrot');
      gotoxy(1,2);
      opcja:=1;
    end;

  var
    tmp: wsk_ksiazka; //pomocnicza zmienna wskaznikowa
    opcja : byte;
  begin
    pisz_menu_dodawania(opcja);//wypisanie menu dodawania na ekranie
    tmp:=nil;
    while (znak<>#8) do //petla az do nacisniecia 'backspace', czyli powrotu do porzedniego menu
      begin
        znak:=#0;
        znak:=readkey;
        case znak of //sterowanie wyborem opcji
          #72 : begin
                  if (wherey<>2) then //ruch wskaznika w gore
                    begin
                      write(' ');
                      gotoxy(wherex-1,wherey-1);
                      write('>');
                      gotoxy(wherex-1,wherey);
                      dec(opcja);
                    end;
          end;
          #80 : begin //ruch wskaznika w dol
                  if (wherey<>3) then
                    begin
                      write(' ');
                      gotoxy(wherex-1,wherey+1);
                      write('>');
                      gotoxy(wherex-1,wherey);
                      inc(opcja);
                    end;
          end;
          #13 : begin
                  case opcja of
                    1 : dodaj_uzytkownika(g_uzytkownicy);
                    2 : dodaj_ksiazke(g_ksiazki,0,tmp);//dodawanie ksiazki; parametr zero i tmp, aby wylaczyc czesc odpowiedzialna za przypisanie ksiazki do uzytkownika
                  end;
                  pisz_menu_dodawania(opcja); //ponowne wypisanie menu dodawania
          end;
          #27 : break;
        end;
      end;
    //zapisz_do_plikow(g_uzytkownicy,g_ksiazki);//zapisanie danych do plikow
  end;

procedure menu (var g_ksiazki: wsk_ksiazka; var g_uzytkownicy : wsk_uzytkownik);
{Procedura obslugi glownego menu. Jako parametry wejsciowe przyjmuje wskazniki na glowe ksiazek i uzytkownikow}
    procedure pisz_menu_glowne(var opcja : byte; var znak : char); //procedura odpowiedzialana za wypisanie opcji glownego menu
  begin
    clrscr;
    gotoxy((windmaxx div 2)-length('Menu'),1);
    Write('Menu');
    gotoxy(2,2);
    write('1. Pokaz uzytkownikow/ksiazki');
    gotoxy(2,3);
    write('2. Dodaj uzytkownika/ksiazke');
    gotoxy(2,4);
    write('3. Info');
    gotoxy(2,5);
    write('4. Wyjscie');
    gotoxy(1,2);
    write('>');
    gotoxy(1,2);
    opcja:=1;
    znak:=#0;
  end;
var
  opcja : byte;
  znak : char;
begin
  while(znak<>#27) do //powtarzaj dopki uzytkownik nie wcisnie klawisza 'ESC'
    begin
      pisz_menu_glowne(opcja,znak); //wypisanie opcji menu na ekranie
      while (znak <> #13) do
        begin
          znak:=#0;
          znak:=readkey; //zczytywanie klawisza
          case znak of
            #72 : begin //ruch w gore wskaznika opcji
                    if (wherey<>2) then
                      begin
                        write(' ');
                        gotoxy(wherex-1,wherey-1);
                        write('>');
                        gotoxy(wherex-1,wherey);
                        dec(opcja);
                      end;
            end;
            #80 : begin //ruch w dol wskaznika opcji
                    if (wherey<>5) then
                      begin
                        write(' ');
                        gotoxy(wherex-1,wherey+1);
                        write('>');
                        gotoxy(wherex-1,wherey);
                        inc(opcja);
                      end;
            end;
            #13 : begin
                    case opcja of
                      1 : wyswietl(g_ksiazki,g_uzytkownicy,znak);//wyswietla wczytane dane
                      2 : dodaj(g_ksiazki,g_uzytkownicy,znak);//przechodzi do dowania nowych elementow
                      3 : INFO;
                      4 : begin
                            znak:=#27;
                            break;
                          end;
                    end;
                    if znak=#27 then break;
                    pisz_menu_glowne(opcja,znak);
            end;
            #27 : break;
          end;
        end;
    end;
  zapisz_do_plikow(g_uzytkownicy,g_ksiazki);
  zwolnij_pamiec(g_ksiazki,g_uzytkownicy);
end;

procedure wczytaj_z_pliku(var g_uzytkownicy : wsk_uzytkownik; var g_ksiazki : wsk_ksiazka);
{Procedura wczytujaca dane dla programu. Jako parametry wejsciowe przyjmuje zmienne plikowe z lista ksiazek oraz uzytkownikow, a takze wskazniki
na glowy list z ksiazkami i uzytkownikami}

    function sprawdz_plik (var plik : text; nazwa : string) : boolean;
    begin
      {$i-}
      reset(plik);
      {$I+}
      if IOResult <> 0 then //jesli jakis blad przy wczytywaniu pliku
        begin
          clrscr;
          writeln(' Blad w pliku: ', nazwa);
          writeln(' Szczegolowe dane nie zostana wczytane...');
          writeln(' Nacisnij ENTER');
          readln;
          chdir('..');
          sprawdz_plik:=true;
        end
      else sprawdz_plik:=false;
    end;

    procedure wczytaj_uzytkownikow(var uzytkownicy :text; var g_uzytkownicy : wsk_uzytkownik; g_ksiazki : wsk_ksiazka);
    {Procedura wczytujaca uzytkownikow i dane o nich z plikow. Jako parametry wejsciowe
    przyjmuje zmienna plikowa z lista uzytkownikow oraz wskaznik na glowe listy uzytkownikow}

        procedure wczytanie_danych_uzytkownika (var tmp : wsk_uzytkownik);
        var
          tmp2,tmp3 : wsk_ksiazka;
          puzytkownik : text;//zmienna plikowa uzyta do zapisywania pelnych informacji o uzytkowniku
          adres: string;//zmienna uzyta do tworzenia osobnych plikow dla kazdego rekordu
        begin
          tmp2:=nil;
          tmp3:=nil;
          sprawdz_folder('uzytkownicy');
          adres:=concat(tmp^.nazwisko,'_',tmp^.imie,'.txt');//laczenie adresu dla kazdego pliku z danymi
          assign(puzytkownik,adres); //przypisanie nazwy pliku do zmiennej
          if sprawdz_plik(puzytkownik,adres)=true then
            begin
              tmp^.glowa_ksiazek:=nil;
              tmp^.pesel:=' ';
              tmp^.ilosc_wypozyczonych_ksiazek:=0;
            end
          else
            begin
              readln(puzytkownik); //wczytywanie kolejnych informacji o aktualnie wczytywanym uzytkowniku
              readln(puzytkownik);
              readln(puzytkownik,tmp^.pesel);
              readln(puzytkownik,tmp^.ilosc_wypozyczonych_ksiazek);
              tmp^.glowa_ksiazek:=nil;
              tmp2:=nil;
              while (not eof(puzytkownik)) do //sprawdzenie czy uzytkownik nie ma wypozyczonych ksiazek
                begin
                  tmp3:=tmp2;
                  if tmp2<>nil then tmp2:=tmp2^.nastepny;
                  new(tmp2);
                  tmp2^.nastepny:=nil;
                  tmp2^.poprzedni:=tmp3;
                  readln(puzytkownik,tmp2^.autor);//wczytywanie kolejnych informacji o aktualnie dodawanej ksiazce
                  readln(puzytkownik,tmp2^.tytul);
                  readln(puzytkownik,tmp2^.wydawnictwo);
                  readln(puzytkownik,tmp2^.rok_miejsce_wydania);
                  readln(puzytkownik,tmp2^.dostepnosc);
                  przypisz_wskaznik_na_orginal(tmp2,g_ksiazki);
                end;
              if tmp2<>nil then
                begin
                  tmp2^.poprzedni:=tmp3;
                  tmp2^.nastepny:=nil;
                  while tmp2^.poprzedni<>nil do
                    tmp2:=tmp2^.poprzedni;
                  tmp^.glowa_ksiazek:=tmp2;
                  while tmp2^.nastepny<>nil do
                    begin
                      tmp2:=tmp2^.nastepny;
                      tmp2^.poprzedni:=nil;
                    end;
                  tmp2:=nil;
                end;
              close(puzytkownik);
              chdir('..');
            end;
        end;

    var
      tmp,tmp1: wsk_uzytkownik; //pomocnicze zmienne wskaznikowe
    begin
      if (eof(uzytkownicy)) then g_uzytkownicy:=nil //jesli plik z lista uzytkownikow nie istnieje, lista uzytkownikow tez nie istnieje
      else
        begin
          tmp:=nil; //zerowanie wskaznikow
          tmp1:=nil;
          g_uzytkownicy:=nil;
          new(tmp);
          tmp^.poprzedni:=nil;
          {$I-}
          while (eof(uzytkownicy)<>true) do //dopoki brak konca pliku
            begin
              readln(uzytkownicy,tmp^.nazwisko);
              readln(uzytkownicy,tmp^.imie);
              wczytanie_danych_uzytkownika(tmp);
              tmp^.nastepny:=nil;
              tmp1:=tmp;
              tmp:=tmp^.nastepny;
              new(tmp);
              tmp^.poprzedni:=tmp1;
              tmp1^.nastepny:=tmp;
            end;
          tmp^.nastepny:=nil;
          {$I+}
          if IOresult <> 0 then
            begin
              gotoxy(2,2);
              write('Naruszono integralnosc plików! Wczytywanie zostaje wstrzymane!');
              gotoxy(2,3);
              write('Nacisnij ENTER');
              readln;
            end;
          if tmp<>nil then
            begin
             tmp:=tmp^.poprzedni; //cofniecie na ostatni wczytany element listy
             dispose(tmp^.nastepny);
             tmp^.nastepny:=nil;
            end;
          if tmp<>nil then
            while(tmp^.poprzedni<>nil) do
              tmp:=tmp^.poprzedni; //przesuniecie glowy na poczatek listy
          g_uzytkownicy:=tmp; //przypisanie parametrowi wejsciowemu adres pocztku listy
       end;
    end;

    procedure wczytaj_ksiazki(var ksiazki :text; var g_ksiazki : wsk_ksiazka);
    {Procedura przyjmuje jako parametr plik z którego wczyta liste istniejacych ksizek
    których dane zapisane są w folderze o nazwie 'ksiazki', pozniej wczyta pelne informacje
    oraz liste tych ksiazek. Zwraca nam wskaźnik na pierwszy element listy wczytanychych
    ksiazek, która jest posortowana (z zalozeniem, ze ktos nie grzebal w plikach)
    }

        procedure wczytanie_danych_ksiazki (var tmp : wsk_ksiazka);
        var
          adres : string; //zmienna przetrzymujaca nazwe pliku dla poszczegolnej ksiazki
          pksiazka : text; //plik tekstowy wskazywany przez aktualny adres
        begin
          sprawdz_folder('ksiazki');
          adres:=concat(tmp^.tytul,'.txt');
          assign(pksiazka,adres);
          if not sprawdz_plik(pksiazka,adres) then
            begin
              readln(pksiazka);//odczytywanie kolejnych informacji ksiazki
              readln(pksiazka,tmp^.autor);
              readln(pksiazka,tmp^.wydawnictwo);
              readln(pksiazka,tmp^.rok_miejsce_wydania);
              readln(pksiazka,tmp^.dostepnosc);
              tmp^.wsk_na_org:=nil;
              close(pksiazka);
              chdir('..');
            end
          else
            begin
              tmp^.autor:=' ';
              tmp^.wydawnictwo:=' ';
              tmp^.rok_miejsce_wydania:=' ';
              tmp^.dostepnosc:=1;
              tmp^.wsk_na_org:=nil;
            end;
        end;

    var
      glowa, tmp, tmp1: wsk_ksiazka; //pomocnicze zmienne wskaznikowe
      pksiazka : text; //plik tekstowy wskazywany przez aktualny adres
    begin
      if (eof(ksiazki)) then g_ksiazki:=nil
      else
        begin
          glowa:=nil;
          tmp:=nil;
          g_ksiazki:=nil;
          new(tmp);
          tmp^.poprzedni:=nil;
          while (eof(ksiazki)<>true) do //dopoki plik sie nie konczy
           begin
              readln(ksiazki,tmp^.tytul);//zczytywanie nazwy pliku z dalszymi danymi ksiazki
              wczytanie_danych_ksiazki(tmp);
              tmp1:=tmp; //zachowanie adresu aktualnie wczytanej ksiazki
              tmp:=tmp^.nastepny;
              new(tmp); //stworzenie nowego elementu listy
              tmp^.poprzedni:=tmp1;
              tmp1^.nastepny:=tmp;
            end;
          if tmp<>nil then
            begin
              tmp:=tmp^.poprzedni;
              dispose(tmp^.nastepny);
              tmp^.nastepny:=nil;
              while (tmp^.poprzedni<> nil) do
                tmp:=tmp^.poprzedni; //przesuniecie glowy na poczatek listy
            end;
          g_ksiazki:=tmp; //przypisanie adresu poczatku listy do parametru listy ksiazek
          glowa:=nil;
          tmp1:=nil;
       end;
    end;
var
  ksiazki, uzytkownicy : text;
begin
  sprawdz_folder('dane');
  assign(uzytkownicy, 'lista_uzytkownicy.txt');
  assign(ksiazki, 'lista_ksiazki.txt');
  if fileexists('lista_ksiazki.txt')=true then //sprawdzenie istnienia pliku z ksiazkami
    begin
      reset(ksiazki);
      wczytaj_ksiazki(ksiazki,g_ksiazki);//wczytanie ksiazek z pliku
      close(ksiazki);
    end;
  if fileexists('lista_uzytkownicy.txt')=true then //sprawdzenie istnienia pliku z uzytkownikami
    begin
      reset(uzytkownicy);
      wczytaj_uzytkownikow(uzytkownicy, g_uzytkownicy, g_ksiazki);//wczytanie uzytkownikow z pliku
      close(uzytkownicy);
    end;

end;

procedure zwolnij_pamiec (var glowa_ksiazki : wsk_ksiazka; var glowa_uzytkownikow : wsk_uzytkownik);
{Procedura odpowiedzialna za zwolnienie pamięci, zajomowanej przez dane prgoramu. Jako parametry
przyjmuje wskaznik na pierwszy element listy ksiazek i listy uzytkownikow}
var //pomocnicze zmienne wskaźnikowe
  tmp_u : wsk_uzytkownik;
begin
  if glowa_uzytkownikow<>nil then //jesli lista uzytkownikow istnieje
    begin
      while glowa_uzytkownikow<>nil do
        begin
          tmp_u:=nil;
          tmp_u:=glowa_uzytkownikow; //przypisanie aktualnego elementu listy do zmiennej pomocniczej
          glowa_uzytkownikow:=glowa_uzytkownikow^.nastepny;
          while tmp_u^.glowa_ksiazek <> nil do
            usun_ksiazki_uzytkownika (glowa_ksiazki, tmp_u^.glowa_ksiazek, 0);
          dispose(tmp_u); //zwolnienie pamieci aktualnego elementu
        end;
      tmp_u:=nil;
      glowa_uzytkownikow:=nil;
    end;
  if glowa_ksiazki <> nil then //jesli lista ksiazek istnieje
    while glowa_ksiazki<>nil do
      usun_ksiazke(glowa_ksiazki,0);
end;

procedure przypisz_wskaznik_na_orginal (var element : wsk_ksiazka; lista_ksiazek : wsk_ksiazka);
{Procedura szuka ksiazki w bibliotece i przypisuje jej wskaznik do pola wsk_na_org wyslanego elementu}
begin
  if lista_ksiazek<>nil then
    begin
      if lista_ksiazek^.nastepny<>nil then
        while (lista_ksiazek^.tytul<>element^.tytul) and (lista_ksiazek^.nastepny<>nil) do
         lista_ksiazek:=lista_ksiazek^.nastepny;
      if lista_ksiazek^.tytul=element^.tytul then
        element^.wsk_na_org:=lista_ksiazek
      else element^.wsk_na_org:=nil;
    end
  else element:=nil;
end;

procedure rysuj;//tworzenie wygladu programu
var
  x,y : integer;
begin
  window(1,1,50,30);
  clrscr;
  for y:=1 to windmaxy-1 do
    if (y=1) or (y=windmaxy-1) then
      for x:=1 to windmaxx do
        begin
          gotoxy(x,y);
          write('#');
        end
    else
      begin
        gotoxy(1,y);
        write('#');
        gotoxy(windmaxx,y);
        write('#');
      end;
  gotoxy(1,windmaxy);
  Write('"Biblioteka" (by Grzegorz Koziol) |');
  gotoxy(windmaxx-length('ESC - Natychmiastowe wyjscie z programu'),windmaxy);
  write('ESC - Natychmiastowe wyjscie z programu');
  window(2,2,windmaxx-1,windmaxy-2);
end;

procedure sprawdz_folder(nazwa : string); //sprawdza i tworzy folder o nazwie wyslany w parametrze
begin
  {$I-}
  chdir(nazwa);
  {$I+}
  if IOresult <> 0 then //jesli jakis blad przy zmianie folderu, stworz nowy
    begin
      clrscr;
      Writeln(' Brak folderu "',nazwa,'", zostanie stworzony teraz...');
      writeln(' Nacisnij Enter');
      readln;
      mkdir(nazwa);
      chdir(nazwa);
    end;
end;

procedure brak_danych;//wyswietlenie monitu o braku danych
begin
  clrscr;
  gotoxy(2,2);
  write('Brak danych! (Nacisnij ENTER)');
  readln;
end;

procedure info;//informacje o programie i autorze
begin
  clrscr;
  Writeln('                       Program "BIBLIOTEKA"');
  Writeln(' Autor : Grzegorz Koziol');
  Writeln(' Program pozwala na zarzadzanie prosta biblioteka.  ');
  Writeln(' Umozliwia dodawania, usuwanie oraz edytowanie ksiazek i uzytkownikow.');
  Writeln(' Program stworzony dla rozmiaru buforu konsoli 80x25.');
  Writeln(' Sterowanie : strzalki kierunkowe, Enter, Backspace, Esc oraz klawisze ');
  Writeln(' alfanumeryczne dla wprowadzania danych i wybierania podopcji. ');
  Writeln(' Klawisz Esc pozwala na natychmiastowe upuszczenie prgramu,');
  Writeln(' z wyjatkiem wprowadzania danych. Uzytkownik odpowiedzialny jest');
  Writeln(' za wprowadzana dane');
  Writeln(' Dlugosc wprowadzanych danych to ',dl_pesel,' dla pesla i ',dl_nazwy,' dla innych danych, ');
  Writeln(' wieksze ciagi znakow zostana uciete do podanej dlugosci. ');
  Writeln(' Uzywanie znakow specjalnych typu: ?,/,\ itd. bedzie skutkowalo');
  Writeln(' niezapisaniem szczegolow poszczegolnych elementow.');
  Writeln(' Zycze milego uzytkowania!');
  Writeln(' Nacisnij ENTER');
  readln;
end;

end.

