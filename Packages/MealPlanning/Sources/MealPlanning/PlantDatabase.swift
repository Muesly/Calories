//
//  PlantDatabase.swift
//  Calories
//
//  Created by Tony Short on 31/01/2026.
//

import Foundation
import CaloriesFoundation

// MARK: - Plant Database

import CaloriesFoundation
public struct PlantDatabase {
    public static let plants: Set<String> = [
        // Vegetables - UK Spellings
        "rocket", "asparagus", "aubergine", "avocado",
        "beetroot", "bok choy", "pak choi", "broccoli", "brussels sprout",
        "cabbage", "carrot", "cauliflower", "celery", "chard",
        "cucumber", "courgette", "kale", "leek", "lettuce",
        "mushrooms", "onion", "parsnip", "peas", "pepper", "red pepper", "green pepper",
        "yellow pepper",
        "potatoes", "new potatoes", "sweet potato", "pumpkin", "radishes", "spinach", "squash",
        "butternut squash",
        "tomato", "turnip", "watercress", "celeriac", "fennel seeds", "artichoke", "okra",
        "sweetcorn",
        "green beans", "runner beans", "french beans", "mange tout", "sugar snap peas",
        "parsnips", "swede",

        // Fruits - UK Spellings
        "apple", "apricot", "banana", "blackberry", "blueberry", "cherry",
        "cranberry", "date", "fig", "grape", "grapefruit", "kiwi fruit", "lemon",
        "lime", "mango", "melon", "nectarine", "orange", "papaya", "passion fruit",
        "peach", "pear", "pineapple", "plum", "pomegranate", "rhubarb",
        "raspberry", "strawberry", "tangerine", "clementine", "satsuma",
        "gooseberry", "blackcurrant", "redcurrant", "whitecurrant",
        "damson", "quince", "loquat", "persimmon", "guava", "cherimoya",

        // Grains & Cereals
        "barley", "buckwheat", "bulgur", "farro", "millet", "oat", "oats",
        "quinoa", "rice", "brown rice", "white rice", "basmati rice", "wild rice", "arborio rice",
        "rye", "spelt", "wheat", "wheatgerm", "amaranth", "sorghum", "teff", "freekeh", "polenta",
        "couscous", "semolina",

        // Legumes
        "bean", "black bean", "kidney bean", "pinto bean", "navy bean",
        "cannellini bean", "butter bean", "lima bean", "chickpea",
        "lentil", "red lentil", "green lentil", "puy lentil", "yellow lentil", "split pea",
        "edamame", "soybean", "lupin", "broad bean", "borlotti bean", "flageolet bean",

        // Nuts
        "almond", "brazil nut", "cashew", "chestnut", "hazelnut", "macadamia",
        "peanut", "pecan", "pine nut", "pistachio", "walnut",
        "candlenut", "litchi nut", "coconut",

        // Seeds
        "chia seed", "flaxseed", "linseed", "hemp seed",
        "poppy seed", "pumpkin seed", "sesame seed", "sunflower seed",
        "fennel seed", "nigella seed", "pumpkin seed", "watermelon seed",

        // Herbs (substantial ones, not just flavoring)
        "basil", "parsley", "coriander leaf", "mint", "dill", "tarragon",
        "oregano", "thyme", "sage", "rosemary", "chives", "marjoram", "lemongrass",

        // Other plant foods
        "seaweed", "nori", "kelp", "spirulina", "chlorella", "cocoa", "cacao",
        "olives", "capers", "nutritional yeast", "miso", "tempeh", "tofu",
    ]
}
