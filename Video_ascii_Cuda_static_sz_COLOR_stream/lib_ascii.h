#ifndef LIB_ASCII_H
#define LIB_ASCII_H
#include <cstring>
#include <cstdio>
#include <cstdlib>
#include <vector>
#include <iostream>
#include <algorithm>
#include <cmath>

// Contient tous les caractères ascii: - 5 pixels de large & 8 pixels de haut   

struct lib_ascii {
    public:
        using PixelType = unsigned char;
        static constexpr std::size_t kwidthCaracter = 7;    // width
        static constexpr std::size_t kheightCaracter = 11;  // height
        static constexpr std::size_t kCaracter = 15;        // nb characters
        static constexpr std::size_t kPixelPerCaracter = kwidthCaracter*kheightCaracter;
    protected:
        static constexpr char kOrderedAscii[kCaracter] {'8','$','&','0','3','4','2','1','*','!',' ','+','@','{','a'}; // "8$&03421*! +@{a"
        static constexpr PixelType kDefaultCaracters[kCaracter * kPixelPerCaracter]{
        0,0,0,0,0,0,0,
        0,0,1,1,1,0,0,
        0,1,0,0,0,1,0,
        0,1,0,0,0,1,0,
        0,0,1,1,1,0,0,
        0,0,1,0,1,0,0,
        0,1,0,0,0,1,0,
        0,1,0,0,0,1,0,
        0,0,1,1,1,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        // idx:56 & ascci: 8
        0,0,0,0,0,0,0,
        0,0,0,1,0,0,0,
        0,0,1,1,1,1,0,
        0,1,1,0,0,1,0,
        0,0,1,1,0,0,0,
        0,0,0,1,1,1,0,
        0,1,0,1,0,1,0,
        0,1,1,1,1,1,0,
        0,0,0,1,0,0,0,
        0,0,0,1,0,0,0,
        0,0,0,0,0,0,0,
        // idx:44 & ascci: $
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,1,1,1,0,0,
        0,0,1,0,0,0,0,
        0,0,1,0,0,0,0,
        0,1,1,1,0,1,0,
        0,1,0,0,1,0,0,
        0,1,1,1,1,1,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        // idx:46 & ascci: &
        0,0,0,0,0,0,0,
        0,0,1,1,1,0,0,
        0,1,1,0,1,1,0,
        0,1,0,0,0,1,0,
        0,1,0,0,0,1,0,
        0,1,0,0,0,1,0,
        0,1,0,0,0,1,0,
        0,1,1,0,1,1,0,
        0,0,1,1,1,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        // idx:48 & ascci: 0
        0,0,0,0,0,0,0,
        0,0,1,1,1,0,0,
        0,1,0,0,0,1,0,
        0,0,0,0,0,1,0,
        0,0,0,1,1,1,0,
        0,0,0,0,0,1,0,
        0,0,0,0,0,1,0,
        0,1,0,0,0,1,0,
        0,0,1,1,1,1,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        // idx:51 & ascci: 3
        0,0,0,0,0,0,0,
        0,0,0,1,1,0,0,
        0,0,0,1,1,0,0,
        0,0,1,1,1,0,0,
        0,0,1,0,1,0,0,
        0,1,1,0,1,0,0,
        0,1,1,1,1,1,0,
        0,0,0,0,1,0,0,
        0,0,0,1,1,1,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        // idx:52 & ascci: 4
        0,0,0,0,0,0,0,  
        0,0,1,1,1,0,0,
        0,1,0,0,0,1,0,
        0,0,0,0,0,1,0,
        0,0,0,0,1,1,0,
        0,0,0,1,1,0,0,
        0,0,1,1,0,0,0,
        0,1,1,0,0,0,0,
        0,1,1,1,1,1,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        // idx:50 & ascci: 2
        0,0,0,0,0,0,0,
        0,0,0,1,0,0,0,
        0,1,1,1,0,0,0,
        0,0,0,1,0,0,0,
        0,0,0,1,0,0,0,
        0,0,0,1,0,0,0,
        0,0,0,1,0,0,0,
        0,0,0,1,0,0,0,
        0,1,1,1,1,1,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        // idx:49 & ascci: 1
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,1,0,0,0,
        0,1,1,1,1,1,0,
        0,0,0,1,0,0,0,
        0,0,1,0,1,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        // idx:42 & ascci: *
        0,0,0,0,0,0,0,
        0,0,0,1,0,0,0,
        0,0,0,1,0,0,0,
        0,0,0,1,0,0,0,
        0,0,0,1,0,0,0,
        0,0,0,1,0,0,0,
        0,0,0,1,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,1,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        // idx:33 & ascci: !
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        // idx:32 & ascci: space
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,1,0,0,0,
        0,0,0,1,0,0,0,
        0,1,1,1,1,1,0,
        0,0,0,1,0,0,0,
        0,0,0,1,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        // idx:43 & ascci: +
        0,0,0,0,0,0,0,
        0,0,1,1,1,1,0,
        0,1,0,0,0,0,1,
        1,0,0,0,1,0,1,
        1,0,1,1,1,0,1,
        1,0,1,0,1,0,1,
        1,0,1,1,1,1,1,
        0,1,0,0,0,0,0,
        0,0,1,1,1,1,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        // idx:64 & ascci: @
        0,0,0,0,0,0,0,
        0,0,0,1,1,1,0,
        0,0,1,0,0,0,0,
        0,0,1,0,0,0,0,
        0,0,1,0,0,0,0,
        0,1,0,0,0,0,0,
        0,0,1,0,0,0,0,
        0,0,1,0,0,0,0,
        0,0,1,0,0,0,0,
        0,0,0,1,1,1,0,
        0,0,0,0,0,0,0,
        // idx:123 & ascci: {
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,1,1,1,0,0,
        0,0,0,0,0,1,0,
        0,0,1,1,1,1,0,
        0,1,0,0,0,1,0,
        0,1,0,0,1,1,0,
        0,0,1,1,0,1,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0
        // idx:123 & ascci: a
        };
        // cpt characters = 15 (mettre a jour cette valeur à chaque modification de kDefaultCaracters)

    public:

    lib_ascii() : lib_ascii{10} {
        // EMPTY
    }

    lib_ascii(size_t caracter_count) : caracter_array_{} {
        const auto first = std::cbegin(kDefaultCaracters);
        const auto last  = first + caracter_count * kPixelPerCaracter;
        caracter_array_.resize(std::distance(first, last));       
        std::copy(first, last, std::begin(caracter_array_));
    }

    template<typename InputIterator>
    lib_ascii(InputIterator first, InputIterator last) : caracter_array_{} {
        while(first != last) {
            const auto position_iterator = std::find(std::cbegin(kOrderedAscii),
                                                     std::cbegin(kOrderedAscii) + kCaracter,
                                                     *first);

            if(position_iterator == (std::cbegin(kOrderedAscii) + kCaracter)) {
                std::cerr << "Error: invalid char \n";
                return;
            }

            const size_t caracter_index = std::distance(std::cbegin(kOrderedAscii),
                                                        position_iterator);

            caracter_array_.insert(std::end(caracter_array_),
                                            std::cbegin(kDefaultCaracters) + caracter_index * kPixelPerCaracter,
                                            std::cbegin(kDefaultCaracters) + (caracter_index + 1) * kPixelPerCaracter);

            ++first;
        }
        
    }

    const PixelType* CaracterArray() const {
        return caracter_array_.data();
    }

    std::size_t RawSize() const {
        return caracter_array_.size();
    }

    std::size_t size() const {
        return RawSize() / kPixelPerCaracter;
    }

    protected:
        std::vector<PixelType> caracter_array_;
};


void affiche_ascii(const lib_ascii &ascii);


#endif