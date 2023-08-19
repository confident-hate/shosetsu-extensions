-- {"id":95556,"ver":"1.0.0","libVer":"1.0.0","author":"Confident-hate"}
local json = Require("dkjson")
local baseURL = "https://www.wattpad.com"

---@param v Element
local text = function(v)
    return v:text()
end


---@param url string
---@param type int
local function shrinkURL(url)
    return url:gsub("https://www.wattpad.com", "")
end

---@param url string
---@param type int
local function expandURL(url)
    return baseURL .. url
end

local ORDER_BY_FILTER = 3
local ORDER_BY_VALUES = { "Hot", "New"}
local GENRE_FILTER = 2
local GENRE_VALUES = { 
  "Adventure",
  "Contemporarylit",
  "Diverselit",
  "Fanfiction",
  "Fantasy",
  "Historicalfiction",
  "Horror",
  "Humor",
  "Lgbt",
  "Mystery",
  "Newadult",
  "Nonfiction",
  "Paranormal",
  "Poetry",
  "Romance",
  "Sciencefiction",
  "Shortstory",
  "Teenfiction",
  "Thriller",
  "Werewolf"
}

local searchFilters = {
    DropdownFilter(GENRE_FILTER, "Genre", GENRE_VALUES),
    DropdownFilter(ORDER_BY_FILTER, "Order by", ORDER_BY_VALUES)
}

local encode = Require("url").encode


--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
    local url = baseURL .. chapterURL
    local htmlElement = GETDocument(url)
    htmlElement = htmlElement:selectFirst(".row.part-content .panel.panel-reading")
    htmlElement:select("button"):remove()
    htmlElement:select("br"):remove()
    local toRemove = {}
    htmlElement:traverse(NodeVisitor(function(v)
        if v:tagName() == "p" and v:text() == "" then
            toRemove[#toRemove+1] = v
        end
    end, nil, true))
    for _,v in pairs(toRemove) do
        v:remove()
    end
    local ht = ""
    local pTagList = ""
    pTagList = map(htmlElement:select("p"), text)
    for k,v in pairs(pTagList) do ht = ht .. "<br><br>" .. v end
    return pageOfElem(Document(ht), true)
end

--- @param data table
local function search(data)
    local query = baseURL .. "/v4/search/stories?query=" .. data[QUERY] .. "&free=1&fields=stories(title,cover,url),nexturl&limit=50&mature=true"
    local response = RequestDocument(GET(query, nil, nil))
    response = json.decode(response:text())

    return map(response["stories"], function(v)
        return Novel {
            title = v.title,
            link = shrinkURL(v.url),
            imageURL = v.cover
        }
    end)

end

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
    local url = baseURL .. novelURL
    local document = RequestDocument(
            RequestBuilder()
                    :get()
                    :url(url)
                    :addHeader("Referer", "https://www.wattpad.com/")
                    :build()
    )
    local isPaid = document:selectFirst(".paid-indicator")
    local description = ""
    if isPaid ~= nil then 
        description = "!! 💰 Paid Story !! \n" .. document:selectFirst(".description-text"):text()
    else
        description = document:selectFirst(".description-text"):text()
    end

    return NovelInfo {
        title = document:selectFirst(".story-info .sr-only"):text(),
        description = description,
        imageURL = document:select(".story-cover img"):attr("src"),
        status = ({
            Ongoing = NovelStatus.PUBLISHING,
            Complete = NovelStatus.COMPLETED,
        })[document:select(".story-badges .tag-item"):text()],
        authors = { document:selectFirst(".author-info__username"):text() },
        genres = map(document:select(".tag-items li a"), text ),
        chapters = AsList(
                map(document:select(".table-of-contents.hidden-xxs ul li"), function(v)
                    local title = v:selectFirst("a .left-container"):text()
                    local chapterRightLabel = v:selectFirst(".right-label"):text()
                    if string.find(chapterRightLabel, "Locked") then
                        title = "🔒 ".. title
                    end
                    return NovelChapter {
                        order = v,
                        title = title,
                        link = v:selectFirst("a"):attr("href")
                    }
                end)
        )
    }
end

local function parseListing(listingURL)
    local document = GETDocument(listingURL)
    return map(document:select("#browse-content #browse-results-item-view .browse-story-item"), function(v)
        return Novel {
            title = v:selectFirst(".item .content .title"):text(),
            imageURL = v:select(".item a img"):attr("src"),
            link = shrinkURL(v:select(".item a"):attr("href"))
        }
    end)
end


local function getListing(data)
    local genre = data[GENRE_FILTER]
    local orderBy = data[ORDER_BY_FILTER]

    local genreValue = ""
    local orderByValue = ""
    if genre ~= nil then
        genreValue = GENRE_VALUES[genre+1]:lower()
    end
    if orderBy ~= nil then
        orderByValue = ORDER_BY_VALUES[orderBy + 1]:lower()
    end
    local url = baseURL .. "/stories/" .. genreValue  .. "/" .. orderByValue
    return parseListing(url)
end



return {
    id = 95556,
    name = "Wattpad",
    baseURL = baseURL,
    imageURL = "https://cdn-icons-png.flaticon.com/512/2111/2111715.png",
    hasSearch = true,
    listings = {
        Listing("Default", true, getListing)
    },

    parseNovel = parseNovel,
    getPassage = getPassage,
    chapterType = ChapterType.HTML,
    search = search,
    shrinkURL = shrinkURL,
    expandURL = expandURL,
    searchFilters = searchFilters
}   