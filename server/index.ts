// const express = require('express');
// const axios = require('axios');
// const dotenv = require('dotenv');

// dotenv.config();

// const app = express();
// app.use(express.json());

// const PORT = 3000;

// app.listen(PORT, () => {
//     console.log(`Server is running on http://localhost:${PORT}`);
// });

// app.post('/ask-ai', async (req, res) => {
//    const question = req.body.question;

//    try {
//        const aiResponse = await axios.post('https://api.openai.com/v1/completions', {
//            prompt: question,
//            model: "text-davinci-003",
//            max_tokens: 150,
//        }, {
//            headers: {
//                'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`
//            }
//        });
       
//        res.json({ answer: aiResponse.data.choices[0].text.trim() });
//    } catch (error) {
//        console.error("Error calling OpenAI API:", error);
//        res.status(500).json({ error: 'Failed to fetch response from AI' });
//    }
// });

