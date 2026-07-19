let text = 'User says \"Hello *smiles* there\"';
let emoteColor = '<RGB:0.8,0.8,0.8>';
let result = text.replace(/\*(.*?)\*/g, (match, p1) => {
    return '*\"' + emoteColor + p1 + ' <RGB:1,1,1>\"*';
});
console.log(result);
