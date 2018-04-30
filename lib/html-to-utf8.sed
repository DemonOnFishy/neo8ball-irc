#!/usr/bin/sed -f
# Copyright 2018 Anthony DeDominic <adedomin@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#
# See the License for the specific language governing permissions and
# limitations under the License.

# common numer char entities...
s/&#x22;/"/g
s/&#34;/"/g
s/&#x27;/'/g
s/&#39;/'/g
s/&#x3[cC];/</g
s/&#60;/</g
s/&#x3[eE];/>/g
s/&#62;/>/g
s/&#x26;/\&/g
s/&#38;/\&/g
# /e is a GNUism by the way.
# also kind of scary given it's literally
# executing /bin/sh -c on that string
# \U is also a bashism... I think.
s/&#\([[:digit:]]\{1,10\}\);/printf '\\U'"$(printf '%x' '\1')"/ge
s/&#x\([[:xdigit:]]\{1,8\}\);/printf '\\U\1'/ge

s/&exclamation;/!/g
s/&quot;/"/g
s/&percent;/%/g
s/&amp;/\&/g
s/&apos;/'/g
s/&add;/+/g
s/&lt;/</g
s/&equal;/=/g
s/&gt;/>/g
s/&nbsp;/ /g
s/&iexcl;/¡/g
s/&cent;/¢/g
s/&pound;/£/g
s/&curren;/¤/g
s/&yen;/¥/g
s/&brvbar;/¦/g
s/&sect;/§/g
s/&uml;/¨/g
s/&copy;/©/g
s/&ordf;/ª/g
s/&laquo;/«/g
s/&not;/¬/g
s/&shy;/<td/g
s/&reg;/®/g
s/&macr;/¯/g
s/&deg;/°/g
s/&plusmn;/±/g
s/&sup2;/²/g
s/&sup3;/³/g
s/&acute;/´/g
s/&micro;/µ/g
s/&para;/¶/g
s/&middot;/·/g
s/&cedil;/¸/g
s/&sup1;/¹/g
s/&ordm;/º/g
s/&raquo;/»/g
s/&frac14;/¼/g
s/&frac12;/½/g
s/&frac34;/¾/g
s/&iquest;/¿/g
s/&Agrave;/À/g
s/&Aacute;/Á/g
s/&Acirc;/Â/g
s/&Atilde;/Ã/g
s/&Auml;/Ä/g
s/&Aring;/Å/g
s/&AElig;/Æ/g
s/&Ccedil;/Ç/g
s/&Egrave;/È/g
s/&Eacute;/É/g
s/&Ecirc;/Ê/g
s/&Euml;/Ë/g
s/&Igrave;/Ì/g
s/&Iacute;/Í/g
s/&Icirc;/Î/g
s/&Iuml;/Ï/g
s/&ETH;/Ð/g
s/&Ntilde;/Ñ/g
s/&Ograve;/Ò/g
s/&Oacute;/Ó/g
s/&Ocirc;/Ô/g
s/&Otilde;/Õ/g
s/&Ouml;/Ö/g
s/&times;/×/g
s/&Oslash;/Ø/g
s/&Ugrave;/Ù/g
s/&Uacute;/Ú/g
s/&Ucirc;/Û/g
s/&Uuml;/Ü/g
s/&Yacute;/Ý/g
s/&THORN;/Þ/g
s/&szlig;/ß/g
s/&agrave;/à/g
s/&aacute;/á/g
s/&acirc;/â/g
s/&atilde;/ã/g
s/&auml;/ä/g
s/&aring;/å/g
s/&aelig;/æ/g
s/&ccedil;/ç/g
s/&egrave;/è/g
s/&eacute;/é/g
s/&ecirc;/ê/g
s/&euml;/ë/g
s/&igrave;/ì/g
s/&iacute;/í/g
s/&icirc;/î/g
s/&iuml;/ï/g
s/&eth;/ð/g
s/&ntilde;/ñ/g
s/&ograve;/ò/g
s/&oacute;/ó/g
s/&ocirc;/ô/g
s/&otilde;/õ/g
s/&ouml;/ö/g
s/&divide;/÷/g
s/&oslash;/ø/g
s/&ugrave;/ù/g
s/&uacute;/ú/g
s/&ucirc;/û/g
s/&uuml;/ü/g
s/&yacute;/ý/g
s/&thorn;/þ/g
s/&yuml;/ÿ/g
s/&OElig;/Œ/g
s/&oelig;/œ/g
s/&Scaron;/Š/g
s/&scaron;/š/g
s/&Yuml;/Ÿ/g
s/&fnof;/ƒ/g
s/&circ;/ˆ/g
s/&tilde;/˜/g
s/&Alpha;/Α/g
s/&Beta;/Β/g
s/&Gamma;/Γ/g
s/&Delta;/Δ/g
s/&Epsilon;/Ε/g
s/&Zeta;/Ζ/g
s/&Eta;/Η/g
s/&Theta;/Θ/g
s/&Iota;/Ι/g
s/&Kappa;/Κ/g
s/&Lambda;/Λ/g
s/&Mu;/Μ/g
s/&Nu;/Ν/g
s/&Xi;/Ξ/g
s/&Omicron;/Ο/g
s/&Pi;/Π/g
s/&Rho;/Ρ/g
s/&Sigma;/Σ/g
s/&Tau;/Τ/g
s/&Upsilon;/Υ/g
s/&Phi;/Φ/g
s/&Chi;/Χ/g
s/&Psi;/Ψ/g
s/&Omega;/Ω/g
s/&alpha;/α/g
s/&beta;/β/g
s/&gamma;/γ/g
s/&delta;/δ/g
s/&epsilon;/ε/g
s/&zeta;/ζ/g
s/&eta;/η/g
s/&theta;/θ/g
s/&iota;/ι/g
s/&kappa;/κ/g
s/&lambda;/λ/g
s/&mu;/μ/g
s/&nu;/ν/g
s/&xi;/ξ/g
s/&omicron;/ο/g
s/&pi;/π/g
s/&rho;/ρ/g
s/&sigmaf;/ς/g
s/&sigma;/σ/g
s/&tau;/τ/g
s/&upsilon;/υ/g
s/&phi;/φ/g
s/&chi;/χ/g
s/&psi;/ψ/g
s/&omega;/ω/g
s/&thetasym;/ϑ/g
s/&upsih;/ϒ/g
s/&piv;/ϖ/g
s/&ensp;/<span/g
s/&emsp;/<span/g
s/&thinsp;/<span/g
s/&zwnj;/<td/g
s/&zwj;/<td/g
s/&lrm;/<td/g
s/&rlm;/<td/g
s/&ndash;/–/g
s/&mdash;/—/g
s/&horbar;/―/g
s/&lsquo;/‘/g
s/&rsquo;/’/g
s/&sbquo;/‚/g
s/&ldquo;/“/g
s/&rdquo;/”/g
s/&bdquo;/„/g
s/&dagger;/†/g
s/&Dagger;/‡/g
s/&bull;/•/g
s/&hellip;/…/g
s/&permil;/‰/g
s/&prime;/′/g
s/&Prime;/″/g
s/&lsaquo;/‹/g
s/&rsaquo;/›/g
s/&oline;/‾/g
s/&frasl;/⁄/g
s/&euro;/€/g
s/&image;/ℑ/g
s/&weierp;/℘/g
s/&real;/ℜ/g
s/&trade;/™/g
s/&alefsym;/ℵ/g
s/&larr;/←/g
s/&uarr;/↑/g
s/&rarr;/→/g
s/&darr;/↓/g
s/&harr;/↔/g
s/&crarr;/↵/g
s/&lArr;/⇐/g
s/&uArr;/⇑/g
s/&rArr;/⇒/g
s/&dArr;/⇓/g
s/&hArr;/⇔/g
s/&forall;/∀/g
s/&part;/∂/g
s/&exist;/∃/g
s/&empty;/∅/g
s/&nabla;/∇/g
s/&isin;/∈/g
s/&notin;/∉/g
s/&ni;/∋/g
s/&prod;/∏/g
s/&sum;/∑/g
s/&minus;/−/g
s/&lowast;/∗/g
s/&radic;/√/g
s/&prop;/∝/g
s/&infin;/∞/g
s/&ang;/∠/g
s/&and;/∧/g
s/&or;/∨/g
s/&cap;/∩/g
s/&cup;/∪/g
s/&int;/∫/g
s/&there4;/∴/g
s/&sim;/∼/g
s/&cong;/≅/g
s/&asymp;/≈/g
s/&ne;/≠/g
s/&equiv;/≡/g
s/&le;/≤/g
s/&ge;/≥/g
s/&sub;/⊂/g
s/&sup;/⊃/g
s/&nsub;/⊄/g
s/&sube;/⊆/g
s/&supe;/⊇/g
s/&oplus;/⊕/g
s/&otimes;/⊗/g
s/&perp;/⊥/g
s/&sdot;/⋅/g
s/&lceil;/⌈/g
s/&rceil;/⌉/g
s/&lfloor;/⌊/g
s/&rfloor;/⌋/g
s/&lang;/〈/g
s/&rang;/〉/g
s/&loz;/◊/g
s/&spades;/♠/g
s/&clubs;/♣/g
s/&hearts;/♥/g
s/&diams;/♦/g
