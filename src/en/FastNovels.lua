-- {"id":95551,"ver":"1.0.0","libVer":"1.0.0","author":"Confident-hate"}

local baseURL = "https://fastnovels.net"

---@param v Element
local function text(v)
    return v:text()
end

---@param url string
---@param type int
local function shrinkURL(url)
    return url:gsub("^.fastnovels.com", "")
end

---@param url string
---@param type int
local function expandURL(url)
    return baseURL .. "/" .. url
end

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
    local htmlElement = GETDocument(baseURL .. "/" .. chapterURL):selectFirst("#chapter-body")
    return pageOfElem(htmlElement, true)
end

--- @param data table
local function search(data)
    local function getSearchResult(queryContent)
        return GETDocument(baseURL .. "/search/" .. queryContent)
    end


    local queryContent = data[QUERY]
    local doc = getSearchResult(queryContent)

    return map(doc:select("li.item > a"), function(v)
        return Novel {
            title = v:attr("title"),
            imageURL = v:selectFirst(".image"):attr("data-original"),
            link = v:attr("href")
        }
    end)
end

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
    local url = baseURL .. "/" .. novelURL
    local document = GETDocument(url)
    local idz = string.match(url, ".*-([0-9]*)/")
    local docU = RequestDocument(POST(url, nil, FormBodyBuilder()
                                :add("id", idz)
                                :add("list_postdata", 1):build()))
    local sz = docU:select("a"):size()
    return NovelInfo {
        title = document:selectFirst(".info > .name"):text(),
        description = document:selectFirst(".content"):text(),
        imageURL = document:selectFirst(".book-cover"):attr("data-original"),
        chapters = AsList(
                map(docU:select("a"), function(v)
                    return NovelChapter {
                        order = sz,
                        title = v:text(),
                        link = baseURL .. v:attr("href")
                    }
                end)
        )
    }

end
return {
    id = 95551,
    name = "FastNovels",
    baseURL = baseURL,
    imageURL = "https://fastnovels.net/images/favicon.png",
    hasSearch = true,
    listings = {
        Listing("Most Popular", false, function()
            local document = GETDocument(baseURL .. "/list/most-popular.html")
            return map(document:select("li.item > a"), function(v)
                return Novel {
                    title = v:attr("title"),
                    imageURL = v:selectFirst(".image"):attr("data-original"),
                    link = v:attr("href")
                }
            end)
        end)
    },
    parseNovel = parseNovel,
    getPassage = getPassage,
    chapterType = ChapterType.HTML,
    search = search,
    shrinkURL = shrinkURL,
    expandURL = expandURL
}
