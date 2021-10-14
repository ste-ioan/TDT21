function [vecteur_beep] = TDTbeep(F_echan, duree_beep, F) % fabrique un vecteur-ligne correspondant à un beep
duree_rampe = 0.01;
nb_echan_son = round(F_echan*duree_beep);
temps_son = 1:nb_echan_son;
nb_echan_rampe = round(F_echan*duree_rampe);
temps_rampe = 1:nb_echan_rampe;
freq_rampe = 0.5/nb_echan_rampe; % 0.5 car les rampes ne font qu'un demi cycle de sinus
onset = (1 + sin(2*pi*freq_rampe*temps_rampe - (pi/2)))/2;
offset = (1 + sin(2*pi*freq_rampe*temps_rampe + (pi/2)))/2;
nb_echan_plateau = nb_echan_son - (2*nb_echan_rampe);
plateau = ones(1, nb_echan_plateau); 
enveloppe = [onset plateau offset];
vecteur_beep = 0.2 * sin(2*pi*F*temps_son./F_echan + rand*2*pi) .* enveloppe;
end