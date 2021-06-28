const tomorrowUnix = () => {
    var today = new Date();
    today.setDate(new Date(today).getDate() + 1);
    return Math.floor(today.getTime() / 1000);
}

module.exports = {
    tomorrowUnix
}
